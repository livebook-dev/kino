defmodule Kino.Table do
  @moduledoc false

  @type info :: %{
          name: String.t(),
          features: list(:refetch | :pagination | :sorting | :filtering)
        }

  @type rows_spec :: %{
          offset: non_neg_integer(),
          limit: pos_integer(),
          order: nil | %{direction: :asc | :desc, key: term()},
          filters:
            list(%{
              filter:
                :less | :less_equal | :equal | :not_equal | :greater_equal | :greater | :contains,
              value: term(),
              key: term()
            })
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
                 data: {:columnar | :row_based, list(list(String.t()))},
                 total_rows: non_neg_integer() | nil
               }, state()}

  use Kino.JS, assets_path: "lib/assets/data_table/build"
  use Kino.JS.Live

  @limit 10

  def new(module, init_arg) do
    Kino.JS.Live.new(__MODULE__, {module, init_arg})
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
       order: nil,
       filters: []
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

  def handle_event("limit", %{"limit" => limit}, ctx) do
    max_page = ceil(ctx.assigns.content.total_rows / limit)
    ctx = if ctx.assigns.content.page > max_page, do: assign(ctx, page: max_page), else: ctx
    {:noreply, ctx |> assign(limit: limit) |> broadcast_update()}
  end

  def handle_event("order_by", %{"key" => nil}, ctx) do
    {:noreply, ctx |> assign(order: nil) |> broadcast_update()}
  end

  def handle_event("order_by", %{"key" => key_string, "direction" => direction}, ctx) do
    direction = String.to_existing_atom(direction)
    key = lookup_key(ctx, key_string)
    ctx = if key, do: assign(ctx, order: %{key: key, direction: direction}), else: ctx
    {:noreply, broadcast_update(ctx)}
  end

  def handle_event("filter_by", %{"key" => key_string, "filter" => filter, "value" => value}, ctx) do
    ctx =
      if key = lookup_key(ctx, key_string) do
        Enum.reject(ctx.assigns.filters, &(&1.key == key))
        |> Kernel.++([%{key: key, filter: filter, value: value}])
        |> then(&assign(ctx, filters: &1))
      else
        ctx
      end

    {:noreply, broadcast_update(ctx)}
  end

  def handle_event("remove_filter", %{"key" => key_string}, ctx) do
    updated_filters = Enum.reject(ctx.assigns.filters, &(&1.key == lookup_key(ctx, key_string)))
    {:noreply, ctx |> assign(filters: updated_filters) |> broadcast_update()}
  end

  def handle_event("reset_filters", _, ctx) do
    {:noreply, ctx |> assign(filters: []) |> broadcast_update()}
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
      order: ctx.assigns.order,
      filters: ctx.assigns.filters
    }

    {:ok, %{columns: columns, data: {orientation, data}, total_rows: total_rows}, state} =
      ctx.assigns.module.get_data(rows_spec, ctx.assigns.state)

    {columns, key_to_string} = stringify_keys(columns, ctx.assigns.key_to_string)

    ctx = assign(ctx, state: state, key_to_string: key_to_string)

    row_based = orientation == :row_based
    page_length = if row_based, do: length(data), else: hd(data) |> length()
    sample_data = if row_based, do: List.first(data), else: Enum.map(data, &List.first(&1))
    has_sample_data = if row_based, do: sample_data, else: Enum.any?(sample_data)

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

    filters = Enum.map(ctx.assigns.filters, &%{&1 | key: key_to_string[&1.key]})

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
      filters: filters,
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
