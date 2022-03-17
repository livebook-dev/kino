defmodule Kino.SmartCell.ChartBuilder do
  use Kino.JS, assets_path: "lib/assets/chart_builder"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Chart builder"

  @as_int ["width", "height"]
  @as_atom ["data", "chart", "x_axis_type", "y_axis_type", "color_type"]

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "chart" => attrs["chart"] || "bar",
      "width" => attrs["width"] || "",
      "height" => attrs["height"] || "",
      "x_axis" => attrs["x_axis"] || "",
      "y_axis" => attrs["y_axis"] || "",
      "x_axis_type" => attrs["x_axis_type"] || "",
      "y_axis_type" => attrs["y_axis_type"] || "",
      "color" => attrs["color"] || "",
      "color_type" => attrs["color_type"] || ""
    }

    {:ok, assign(ctx, fields: fields, options: %{}, vl_alias: nil, missing_dep: missing_dep())}
  end

  @impl true
  def scan_binding(pid, binding, env) do
    dfs = Keyword.filter(binding, fn {_key, val} -> is_map(val) end)
    data_options = Map.new(dfs, fn {k, v} -> {k, Map.keys(v)} end)
    vl_alias = vl_alias(env)
    send(pid, {:scan_binding_result, data_options, vl_alias})
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields,
      missing_dep: ctx.assigns.missing_dep,
      options: ctx.assigns.options
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_info({:scan_binding_result, data_options, vl_alias}, ctx) do
    ctx = assign(ctx, options: data_options, vl_alias: vl_alias)
    broadcast_event(ctx, "set_data_options", %{"options" => data_options})

    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    updated_fields = %{field => value}
    ctx = update(ctx, :fields, &Map.merge(&1, updated_fields))
    if field == "data", do: update_options(ctx, value)

    broadcast_event(ctx, "update", %{"fields" => updated_fields})

    {:noreply, ctx}
  end

  defp update_options(ctx, df) do
    df = String.to_atom(df)
    options = ctx.assigns.options[df]
    broadcast_event(ctx, "set_axis_options", %{"options" => options})
  end

  defp convert_field(field, ""), do: {String.to_atom(field), nil}

  defp convert_field(field, value) when field in @as_int do
    {String.to_atom(field), String.to_integer(value)}
  end

  defp convert_field(field, value) when field in @as_atom do
    {String.to_atom(field), String.to_atom(value)}
  end

  defp convert_field(field, value), do: {String.to_atom(field), value}

  defp vl_alias(%Macro.Env{aliases: aliases}) do
    Enum.find_value(aliases, fn {current_alias, module} ->
      if module == VegaLite, do: current_alias
    end)
  end

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.fields
    |> Map.put("vl_alias", ctx.assigns.vl_alias)
  end

  @impl true
  def to_source(attrs) do
    attrs
    |> to_quoted()
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end

  defp to_quoted(%{"data" => ""}), do: nil

  defp to_quoted(attrs) do
    data = if attrs["data"], do: String.to_atom(attrs["data"]), else: nil
    module = if attrs["vl_alias"], do: attrs["vl_alias"], else: VegaLite
    module = Module.split(module) |> hd() |> String.to_atom()

    attrs = Map.new(attrs, fn {k, v} -> convert_field(k, v) end)

    [root | nodes] = [
      %{
        field: nil,
        name: :new,
        module: module,
        args: [[width: attrs.width, height: attrs.height]]
      },
      %{field: :data, name: :data_from_series, module: module, args: [Macro.var(data, nil)]},
      %{field: :mark, name: :mark, module: module, args: [attrs.chart]},
      %{
        field: :x,
        name: :encode_field,
        module: module,
        args: [attrs.x_axis, [type: attrs.x_axis_type]]
      },
      %{
        field: :y,
        name: :encode_field,
        module: module,
        args: [attrs.y_axis, [type: attrs.y_axis_type]]
      },
      %{
        field: :color,
        name: :encode_field,
        module: module,
        args: [attrs.color, [type: attrs.color_type]]
      }
    ]

    root = build_root(root)

    nodes
    |> Enum.map(&clean_node(&1))
    |> Enum.reduce(root, &apply_node/2)
  end

  defp build_root(root) do
    args =
      root.args
      |> Enum.at(0)
      |> Enum.filter(&elem(&1, 1))
      |> case do
        [] -> []
        opts -> [opts]
      end

    {{:., [], [{:__aliases__, [alias: false], [root.module]}, root.name]}, [], args}
  end

  def clean_node(node) do
    Map.replace!(node, :args, clean_args(node.args))
  end

  defp apply_node(%{args: nil}, acc), do: acc
  defp apply_node(%{args: []}, acc), do: acc

  defp apply_node(%{field: field, name: function, module: module, args: args}, acc) do
    ctx = [context: Elixir, import: Kernel]
    args = if function == :encode_field, do: List.insert_at(args, 0, field), else: args

    {:|>, ctx,
     [
       acc,
       {{:., [], [{:__aliases__, [alias: false], [module]}, function]}, [], args}
     ]}
  end

  defp clean_args(args) do
    opts =
      args
      |> Enum.filter(&is_list/1)
      |> List.flatten()
      |> Enum.filter(&elem(&1, 1))

    args = Enum.reject(args, &(is_list(&1) or is_nil(&1)))

    if opts != [], do: List.insert_at(args, -1, opts), else: args
  end

  defp missing_dep() do
    unless Code.ensure_loaded?(VegaLite) do
      ~s/{:vega_lite, "~> 0.1.2"}/
    end
  end
end
