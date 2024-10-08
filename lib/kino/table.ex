defmodule Kino.Table do
  @moduledoc """
  A behaviour module for implementing tabular kinos.

  This module implements table visualization and delegates data
  fetching and traversal to the behaviour implementation.
  """

  @type info :: %{
          :name => String.t(),
          :features => list(:export | :refetch | :pagination | :sorting | :relocate),
          optional(:export) => %{formats: list(String.t())},
          optional(:num_rows) => pos_integer()
        }

  @type rows_spec :: %{
          offset: non_neg_integer(),
          limit: pos_integer(),
          order: nil | %{direction: :asc | :desc, key: term()},
          relocates: list(%{from_index: non_neg_integer(), to_index: non_neg_integer()})
        }

  @type column :: %{
          :key => term(),
          :label => String.t(),
          optional(:type) => type(),
          optional(:summary) => %{String.t() => String.t()}
        }

  @typedoc """
  The following types have meaning on the front-end:

    * "date"
    * "list"
    * "number"
    * "struct"
    * "text"
    * "uri"

  """
  @type type :: String.t()

  @type state :: term()

  @doc """
  Invoked once to initialize server state.
  """
  @callback init(init_arg :: term()) :: {:ok, info(), state()}

  @doc """
  Loads data matching the given specification.
  """
  @callback get_data(rows_spec(), state()) ::
              {:ok,
               %{
                 columns: list(column()),
                 data: {:columns | :rows, list(list(String.t()))},
                 total_rows: non_neg_integer() | nil
               }, state()}

  @doc """
  Exports the data for download.

  The returned map must contain the binary, the file extension and the mime type.
  """
  @callback export_data(rows_spec(), state(), String.t()) ::
              {:ok, %{data: binary(), extension: String.t(), type: String.t()}}

  @doc """
  Invoked to update state with new data.

  This callback is called in response to `update/2`.
  """
  @callback on_update(update_arg :: term(), state :: state()) :: {:ok, state()}

  @optional_callbacks export_data: 3, on_update: 2

  use Kino.JS, assets_path: "lib/assets/data_table/build"
  use Kino.JS.Live

  @type t :: Kino.JS.Live.t()

  @limit 10

  @doc """
  Creates a new tabular kino using the given module as data
  specification.

  ## Options

    * `:export` - a function called to export the given kino to Markdown.
      This works the same as `Kino.JS.new/3`, except the function
      receives the state as an argument

  """
  @spec new(module(), term(), keyword()) :: t()
  def new(module, init_arg, opts \\ []) do
    export =
      if export = opts[:export] do
        fn ctx -> export.(ctx.assigns.state) end
      end

    Kino.JS.Live.new(__MODULE__, {module, init_arg}, export: export)
  end

  @doc """
  Updates the table with new data.

  An arbitrary update event can be used and it is then handled by
  the `c:on_update/2` callback.
  """
  @spec update(t(), term()) :: :ok
  def update(kino, update_arg) do
    Kino.JS.Live.cast(kino, {:update, update_arg})
  end

  @impl true
  def init({module, init_arg}, ctx) do
    {:ok, info, state} = module.init(init_arg)

    {:ok,
     assign(ctx,
       module: module,
       info: info,
       state: state,
       key_to_string: %{},
       content: nil,
       # Data specification
       page: 1,
       limit: info[:num_rows] || @limit,
       order: nil,
       relocates: []
     )}
  end

  @impl true
  def handle_connect(ctx) do
    ctx =
      if ctx.assigns.content do
        ctx
      else
        {content, ctx} = get_content(ctx)
        assign(ctx, content: content)
      end

    payload = %{
      name: ctx.assigns.info.name,
      features: ctx.assigns.info.features,
      export: ctx.assigns.info[:export],
      content: ctx.assigns.content
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_event("show_page", %{"page" => page}, ctx) do
    {:noreply, ctx |> assign(page: page) |> broadcast_update()}
  end

  def handle_event("refetch", _payload, ctx) do
    {:noreply, broadcast_update(ctx)}
  end

  def handle_event("download", %{"format" => format}, ctx) do
    {:ok, exported} = ctx.assigns.module.export_data(rows_spec(ctx), ctx.assigns.state, format)
    info = %{filename: ctx.assigns.info.name, type: exported.type, format: exported.extension}
    reply_payload = {:binary, info, exported.data}
    send_event(ctx, ctx.origin, "download_content", reply_payload)
    {:noreply, ctx}
  end

  def handle_event("limit", %{"limit" => limit}, ctx) do
    total_rows = ctx.assigns.content.total_rows
    max_page = if total_rows, do: ceil(total_rows / limit)
    ctx = if ctx.assigns.content.page > max_page, do: assign(ctx, page: max_page), else: ctx
    {:noreply, ctx |> assign(limit: limit) |> broadcast_update()}
  end

  def handle_event("order_by", %{"key" => nil}, ctx) do
    {:noreply, ctx |> reset() |> broadcast_update()}
  end

  def handle_event("order_by", %{"key" => key_string, "direction" => direction}, ctx) do
    direction = String.to_existing_atom(direction)
    key = lookup_key(ctx, key_string)
    ctx = if key, do: assign(ctx, order: %{key: key, direction: direction}, page: 1), else: ctx
    {:noreply, broadcast_update(ctx)}
  end

  def handle_event("relocate", %{"from_index" => from_index, "to_index" => to_index}, ctx) do
    relocates = ctx.assigns.relocates ++ [%{from_index: from_index, to_index: to_index}]
    {:noreply, ctx |> assign(relocates: relocates) |> broadcast_update()}
  end

  @impl true
  def handle_cast({:update, update_arg}, ctx) do
    unless Kino.Utils.has_function?(ctx.assigns.module, :on_update, 2) do
      raise ArgumentError, "module #{inspect(ctx.assigns.module)} does not define on_update/2"
    end

    {:ok, state} = ctx.assigns.module.on_update(update_arg, ctx.assigns.state)
    {:noreply, assign(ctx, state: state) |> reset() |> broadcast_update()}
  end

  defp reset(ctx), do: assign(ctx, order: nil, page: 1)

  defp broadcast_update(ctx) do
    {content, ctx} = get_content(ctx)
    broadcast_event(ctx, "update_content", content)
    assign(ctx, content: content)
  end

  defp get_content(ctx) do
    {:ok, %{columns: columns, data: {orientation, data}, total_rows: total_rows}, state} =
      ctx.assigns.module.get_data(rows_spec(ctx), ctx.assigns.state)

    {columns, key_to_string} = stringify_keys(columns, ctx.assigns.key_to_string)

    ctx = assign(ctx, state: state, key_to_string: key_to_string)

    {page_length, sample_data} = sample_data(data, orientation)

    columns =
      if sample_data != [] do
        sample_data
        |> infer_types()
        |> Enum.zip_with(columns, fn type, column ->
          Map.put_new(column, :type, type)
        end)
      else
        columns
      end

    order =
      if ctx.assigns.order,
        do: %{ctx.assigns.order | key: key_to_string[ctx.assigns.order.key]}

    content = %{
      data: data,
      data_orientation: orientation,
      columns: columns,
      page: ctx.assigns.page,
      page_length: page_length,
      max_page: total_rows && ceil(total_rows / ctx.assigns.limit),
      total_rows: total_rows,
      order: order,
      limit: ctx.assigns.limit,
      relocates: ctx.assigns.relocates
    }

    {content, ctx}
  end

  defp infer_types(sample_data) do
    Enum.map(sample_data, &type_of/1)
  end

  defp type_of("http" <> _rest), do: "uri"

  defp type_of(data) do
    cond do
      number?(data) -> "number"
      date?(data) or date_time?(data) -> "date"
      true -> "text"
    end
  end

  defp number?(value), do: match?({_, ""}, Float.parse(value))
  defp date?(value), do: match?({:ok, _}, Date.from_iso8601(value))
  defp date_time?(value), do: match?({:ok, _, _}, DateTime.from_iso8601(value))

  # Map keys to string representation for the client side
  defp stringify_keys(columns, key_to_string) do
    {columns, key_to_string} =
      Enum.map_reduce(columns, key_to_string, fn column, key_to_string ->
        key_to_string =
          Map.put_new_lazy(key_to_string, column.key, fn ->
            key_to_string |> map_size() |> Integer.to_string()
          end)

        column = %{column | key: key_to_string[column.key]}

        {column, key_to_string}
      end)

    {columns, key_to_string}
  end

  defp lookup_key(ctx, key_string) do
    ctx.assigns.key_to_string
    |> Enum.find(&match?({_key, ^key_string}, &1))
    |> case do
      {key, _key_string} -> key
      _ -> nil
    end
  end

  defp rows_spec(ctx) do
    %{
      offset: (ctx.assigns.page - 1) * ctx.assigns.limit,
      limit: ctx.assigns.limit,
      order: ctx.assigns.order,
      relocates: ctx.assigns.relocates
    }
  end

  defp sample_data([], _), do: {0, []}
  defp sample_data(data, :rows), do: {length(data), hd(data)}
  defp sample_data([[] | _], :columns), do: {0, []}
  defp sample_data(data, :columns), do: {length(hd(data)), Enum.map(data, &List.first(&1))}
end
