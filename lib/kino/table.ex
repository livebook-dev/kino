defmodule Kino.Table do
  @moduledoc """
  A behaviour module for implementing tabular kinos.

  This module implements table visualization and delegates data
  fetching and traversal to the behaviour implementation.
  """

  @type info :: %{
          :name => String.t(),
          :features => list(:export | :refetch | :pagination | :sorting),
          optional(:export) => %{formats: list(String.t())}
        }

  @type rows_spec :: %{
          offset: non_neg_integer(),
          limit: pos_integer(),
          order: nil | %{direction: :asc | :desc, key: term()}
        }

  @type column :: %{
          :key => term(),
          :label => String.t(),
          optional(:type) => String.t(),
          optional(:summary) => %{String.t() => String.t()}
        }

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
  @callback export_data(state(), String.t()) ::
              {:ok, %{data: binary(), extension: String.t(), type: String.t()}}

  @optional_callbacks export_data: 2

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
       limit: @limit,
       order: nil
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
    exported = ctx.assigns.module.export_data(ctx.assigns.state, format)
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
    {:noreply, ctx |> assign(order: nil, page: 1) |> broadcast_update()}
  end

  def handle_event("order_by", %{"key" => key_string, "direction" => direction}, ctx) do
    direction = String.to_existing_atom(direction)
    key = lookup_key(ctx, key_string)
    ctx = if key, do: assign(ctx, order: %{key: key, direction: direction}, page: 1), else: ctx
    {:noreply, broadcast_update(ctx)}
  end

  defp broadcast_update(ctx) do
    {content, ctx} = get_content(ctx)
    broadcast_event(ctx, "update_content", content)
    assign(ctx, content: content)
  end

  defp get_content(ctx) do
    rows_spec = %{
      offset: (ctx.assigns.page - 1) * ctx.assigns.limit,
      limit: ctx.assigns.limit,
      order: ctx.assigns.order
    }

    {:ok, %{columns: columns, data: {orientation, data}, total_rows: total_rows}, state} =
      ctx.assigns.module.get_data(rows_spec, ctx.assigns.state)

    {columns, key_to_string} = stringify_keys(columns, ctx.assigns.key_to_string)

    ctx = assign(ctx, state: state, key_to_string: key_to_string)

    {page_length, sample_data} =
      case orientation do
        :rows -> {length(data), List.first(data)}
        :columns -> {hd(data) |> length(), Enum.map(data, &List.first(&1))}
      end

    has_sample_data = if is_list(sample_data), do: Enum.any?(sample_data)

    columns =
      if has_sample_data do
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
      limit: ctx.assigns.limit
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
end
