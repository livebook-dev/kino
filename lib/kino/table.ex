defmodule Kino.Table do
  @moduledoc false

  @type info :: %{
          name: String.t(),
          features: list(:refetch | :pagination | :sorting)
        }

  @type rows_spec :: %{
          offset: non_neg_integer(),
          limit: pos_integer(),
          order_by: nil | term(),
          order: :asc | :desc
        }

  @type column :: %{
          :key => term(),
          :label => String.t(),
          optional(:type) => String.t()
        }

  @type row :: %{
          # A string value for every column key
          fields: list(%{term() => String.t()})
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
                 rows: list(row()),
                 total_rows: non_neg_integer() | nil
               }, state()}

  use Kino.JS, assets_path: "lib/assets/data_table"
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
       order_by: nil,
       order: :asc
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

  def handle_event("order_by", %{"key" => key_string, "order" => order}, ctx) do
    order = String.to_existing_atom(order)

    ctx =
      if key_string do
        # Lookup key by the string representation received from the client
        ctx.assigns.key_to_string
        |> Enum.find(&match?({_key, ^key_string}, &1))
        |> case do
          {key, _key_string} -> assign(ctx, order_by: key, order: order)
          _ -> ctx
        end
      else
        assign(ctx, order_by: nil, order: :asc)
      end

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
      order_by: ctx.assigns.order_by,
      order: ctx.assigns.order
    }

    {:ok, %{columns: columns, rows: rows, total_rows: total_rows}, state} =
      ctx.assigns.module.get_data(rows_spec, ctx.assigns.state)

    {columns, rows, key_to_string} = stringify_keys(columns, rows, ctx.assigns.key_to_string)

    ctx = assign(ctx, state: state, key_to_string: key_to_string)

    content = %{
      rows: rows,
      columns: columns,
      page: ctx.assigns.page,
      max_page: total_rows && ceil(total_rows / ctx.assigns.limit),
      total_rows: total_rows,
      order: ctx.assigns.order,
      order_by: key_to_string[ctx.assigns.order_by]
    }

    {content, ctx}
  end

  # Map keys to string representation for the client side
  defp stringify_keys(columns, rows, key_to_string) do
    {columns, key_to_string} =
      Enum.map_reduce(columns, key_to_string, fn column, key_to_string ->
        key_to_string =
          Map.put_new_lazy(key_to_string, column.key, fn ->
            key_to_string |> map_size() |> Integer.to_string()
          end)

        column = %{column | key: key_to_string[column.key]}

        {column, key_to_string}
      end)

    rows =
      update_in(rows, [Access.all(), :fields], fn fields ->
        Map.new(fields, fn {key, value} ->
          {key_to_string[key], value}
        end)
      end)

    {columns, rows, key_to_string}
  end
end
