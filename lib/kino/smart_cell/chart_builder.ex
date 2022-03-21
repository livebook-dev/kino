defmodule Kino.SmartCell.ChartBuilder do
  use Kino.JS, assets_path: "lib/assets/chart_builder"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Chart builder"

  @as_int ["width", "height"]
  @as_atom ["data_variable", "chart_type", "x_field_type", "y_field_type", "color_field_type"]

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "chart_type" => attrs["chart_type"] || "bar",
      "width" => attrs["width"] || "",
      "height" => attrs["height"] || "",
      "x_field" => attrs["x_field"] || "",
      "y_field" => attrs["y_field"] || "",
      "x_field_type" => attrs["x_field_type"] || "",
      "y_field_type" => attrs["y_field_type"] || "",
      "color_field" => attrs["color_field"] || "",
      "color_field_type" => attrs["color_field_type"] || "",
      "data_variable" => attrs["data_variable"] || ""
    }

    ctx =
      assign(ctx,
        fields: fields,
        options: %{},
        vl_alias: nil,
        missing_dep: missing_dep(),
        fresh: attrs == %{}
      )

    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def scan_binding(pid, binding, env) do
    data_options =
      for {key, val} <- binding, is_atom(key), is_map(val), into: %{}, do: {key, Map.keys(val)}

    vl_alias = vl_alias(env)
    send(pid, {:scan_binding_result, data_options, vl_alias})
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields,
      missing_dep: ctx.assigns.missing_dep,
      options: ctx.assigns.options,
      fresh: ctx.assigns.fresh
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_info({:scan_binding_result, data_options, vl_alias}, ctx) do
    ctx = assign(ctx, options: data_options, vl_alias: vl_alias)
    broadcast_event(ctx, "set_available_data", %{"options" => data_options})

    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    current_data = ctx.assigns.fields["data_variable"]
    current_field = ctx.assigns.fields[field]

    updated_fields = %{field => value}
    ctx = update(ctx, :fields, &Map.merge(&1, updated_fields))

    if field == "data_variable" && value != current_data, do: update_options(ctx, value)
    if value != current_field, do: broadcast_event(ctx, "update", %{"fields" => updated_fields})

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
    case List.keyfind(aliases, VegaLite, 1) do
      {vl_alias, _} -> vl_alias
      nil -> VegaLite
    end
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
    |> Kino.Utils.Code.quoted_to_string()
  end

  defp to_quoted(%{"data_variable" => ""}) do
    quote do
    end
  end

  defp to_quoted(attrs) do
    data = if attrs["data_variable"], do: String.to_atom(attrs["data_variable"]), else: nil

    attrs = Map.new(attrs, fn {k, v} -> convert_field(k, v) end)

    [root | nodes] = [
      %{
        field: nil,
        name: :new,
        module: attrs.vl_alias,
        args: [[width: attrs.width, height: attrs.height]]
      },
      %{
        field: :data,
        name: :data_from_series,
        module: attrs.vl_alias,
        args: [Macro.var(data, nil)]
      },
      %{field: :mark, name: :mark, module: attrs.vl_alias, args: [attrs.chart_type]},
      %{
        field: :x,
        name: :encode_field,
        module: attrs.vl_alias,
        args: [attrs.x_field, [type: attrs.x_field_type]]
      },
      %{
        field: :y,
        name: :encode_field,
        module: attrs.vl_alias,
        args: [attrs.y_field, [type: attrs.y_field_type]]
      },
      %{
        field: :color,
        name: :encode_field,
        module: attrs.vl_alias,
        args: [attrs.color_field, [type: attrs.color_field_type]]
      }
    ]

    root = build_root(root)

    nodes
    |> Enum.map(&clean_node/1)
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

    quote do
      unquote(root.module).unquote(root.name)(unquote_splicing(args))
    end
  end

  def clean_node(node) do
    Map.replace!(node, :args, clean_args(node.args))
  end

  defp apply_node(%{args: nil}, acc), do: acc
  defp apply_node(%{args: []}, acc), do: acc

  defp apply_node(%{field: field, name: function, module: module, args: args}, acc) do
    args = if function == :encode_field, do: List.insert_at(args, 0, field), else: args

    quote do
      unquote(acc) |> unquote(module).unquote(function)(unquote_splicing(args))
    end
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
