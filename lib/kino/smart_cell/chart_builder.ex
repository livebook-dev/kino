defmodule Kino.SmartCell.ChartBuilder do
  use Kino.JS, assets_path: "lib/assets/chart_builder"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Chart builder"

  @as_int ["width", "height"]
  @as_atom [
    "data_variable",
    "chart_type",
    "x_field_type",
    "y_field_type",
    "color_field_type",
    "x_field_aggregate",
    "y_field_aggregate",
    "color_field_aggregate"
  ]

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "chart_type" => attrs["chart_type"] || "bar",
      "data_variable" => attrs["data_variable"],
      "width" => attrs["width"],
      "height" => attrs["height"],
      "x_field" => attrs["x_field"],
      "y_field" => attrs["y_field"],
      "color_field" => attrs["color_field"],
      "x_field_type" => attrs["x_field_type"],
      "y_field_type" => attrs["y_field_type"],
      "color_field_type" => attrs["color_field_type"],
      "x_field_aggregate" => attrs["x_field_aggregate"],
      "y_field_aggregate" => attrs["y_field_aggregate"],
      "color_field_aggregate" => attrs["color_field_aggregate"],
      "chart_title" => attrs["chart_title"]
    }

    ctx =
      assign(ctx,
        fields: fields,
        data_options: %{},
        vl_alias: nil,
        missing_dep: missing_dep(),
        fresh: is_fresh?(attrs)
      )

    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def scan_binding(pid, binding, env) do
    data_options =
      for {key, val} <- binding,
          is_atom(key),
          is_valid_data(val),
          into: %{},
          do: {Atom.to_string(key), val |> Map.keys() |> Enum.map(&to_string/1)}

    vl_alias = vl_alias(env)
    send(pid, {:scan_binding_result, data_options, vl_alias})
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields,
      missing_dep: ctx.assigns.missing_dep,
      data_options: ctx.assigns.data_options,
      fresh: ctx.assigns.fresh
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_info({:scan_binding_result, data_options, vl_alias}, ctx) do
    ctx = assign(ctx, data_options: data_options, vl_alias: vl_alias)
    broadcast_event(ctx, "set_available_data", %{"data_options" => data_options})

    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => "data_variable", "value" => value}, ctx) do
    updated_fields = updates_for_data_variable(ctx, value)
    ctx = update(ctx, :fields, &Map.merge(&1, updated_fields))
    broadcast_event(ctx, "update", %{"fields" => updated_fields})

    {:noreply, ctx}
  end

  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    parsed_value = parse_value(field, value)
    ctx = update(ctx, :fields, &Map.put(&1, field, parsed_value))
    broadcast_event(ctx, "update", %{"fields" => %{field => parsed_value}})

    {:noreply, ctx}
  end

  defp updates_for_data_variable(ctx, value) do
    {x_field, y_field} =
      case ctx.assigns.data_options[value] do
        [key] -> {key, key}
        [key1, key2 | _] -> {key1, key2}
        _ -> {nil, nil}
      end

    %{
      "data_variable" => value,
      "x_field" => x_field,
      "y_field" => y_field,
      "color_field" => nil,
      "x_field_type" => nil,
      "y_field_type" => nil,
      "color_field_type" => nil,
      "x_field_aggregate" => nil,
      "y_field_aggregate" => nil,
      "color_field_aggregate" => nil,
      "chart_title" => nil
    }
  end

  defp parse_value(_field, ""), do: nil
  defp parse_value(field, value) when field in @as_int, do: String.to_integer(value)
  defp parse_value(_field, value), do: value

  defp convert_field(field, nil), do: {String.to_atom(field), nil}

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

  defp to_quoted(%{"data_variable" => nil}) do
    quote do
    end
  end

  defp to_quoted(attrs) do
    attrs = Map.new(attrs, fn {k, v} -> convert_field(k, v) end)

    [root | nodes] = [
      %{
        field: nil,
        name: :new,
        module: attrs.vl_alias,
        args: build_arg_root(width: attrs.width, height: attrs.height, title: attrs.chart_title)
      },
      %{
        field: :data,
        name: :data_from_series,
        module: attrs.vl_alias,
        args: [Macro.var(attrs.data_variable, nil)]
      },
      %{field: :mark, name: :mark, module: attrs.vl_alias, args: [attrs.chart_type]},
      %{
        field: :x,
        name: :encode_field,
        module: attrs.vl_alias,
        args: build_arg_field(attrs.x_field, attrs.x_field_type, attrs.x_field_aggregate)
      },
      %{
        field: :y,
        name: :encode_field,
        module: attrs.vl_alias,
        args: build_arg_field(attrs.y_field, attrs.y_field_type, attrs.y_field_aggregate)
      },
      %{
        field: :color,
        name: :encode_field,
        module: attrs.vl_alias,
        args:
          build_arg_field(attrs.color_field, attrs.color_field_type, attrs.color_field_aggregate)
      }
    ]

    root = build_root(root)
    Enum.reduce(nodes, root, &apply_node/2)
  end

  defp build_root(root) do
    quote do
      unquote(root.module).unquote(root.name)(unquote_splicing(root.args))
    end
  end

  defp apply_node(%{args: nil}, acc), do: acc

  defp apply_node(%{field: field, name: function, module: module, args: args}, acc) do
    args = if function == :encode_field, do: List.insert_at(args, 0, field), else: args

    quote do
      unquote(acc) |> unquote(module).unquote(function)(unquote_splicing(args))
    end
  end

  defp build_arg_root(opts) do
    opts
    |> Enum.filter(&elem(&1, 1))
    |> case do
      [] -> []
      opts -> [opts]
    end
  end

  defp build_arg_field(nil, _, _), do: nil
  defp build_arg_field(field, nil, nil), do: [field]
  defp build_arg_field(field, type, nil), do: [field, [type: type]]
  defp build_arg_field(field, nil, aggregate), do: [field, [aggregate: aggregate]]
  defp build_arg_field(field, type, aggregate), do: [field, [type: type, aggregate: aggregate]]

  defp missing_dep() do
    unless Code.ensure_loaded?(VegaLite) do
      ~s/{:vega_lite, "~> 0.1.2"}/
    end
  end

  defp is_fresh?(attrs) do
    attrs
    |> Map.drop(["chart_type", "vl_alias"])
    |> Map.values()
    |> Enum.any?()
    |> then(&(!&1))
  end

  defp is_valid_data(data) when is_map(data) and data != %{} do
    Enum.all?(data, fn {key, val} ->
      String.Chars.impl_for(key) != nil and Enumerable.impl_for(val) != nil
    end)
  end

  defp is_valid_data(_), do: false
end
