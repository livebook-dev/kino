defmodule Kino.SmartCell.ChartBuilderTest do
  use Kino.LivebookCase, async: true

  import KinoTest.JS.Live
  import KinoTest.SmartCell

  alias Kino.SmartCell.ChartBuilder

  @root %{
    "width" => nil,
    "height" => nil,
    "chart_title" => nil,
    "vl_alias" => VegaLite
  }

  @layer %{
    "chart_type" => "bar",
    "data_variable" => "data",
    "x_field" => "a",
    "y_field" => "b",
    "color_field" => nil,
    "x_field_type" => nil,
    "y_field_type" => nil,
    "color_field_type" => nil,
    "x_field_aggregate" => nil,
    "y_field_aggregate" => nil,
    "color_field_aggregate" => nil
  }

  test "returns no source when starting fresh with no data" do
    {_widget, source} = start_smart_cell!(ChartBuilder, %{})

    assert source == ""
  end

  test "finds tabular data in binding and sends new options to the client" do
    {widget, _source} = start_smart_cell!(ChartBuilder, %{})

    row_data = [%{x: 1, y: 1}, %{x: 2, y: 2}]
    column_data = %{x: 1..2, y: 1..2}
    invalid_data = %{self() => [1, 2], :y => [1, 2]}

    binding = [row_data: row_data, column_data: column_data, invalid_data: invalid_data]
    # TODO: Use Code.env_for_eval on Elixir v1.14+
    env = :elixir.env_for_eval([])
    ChartBuilder.scan_binding(widget.pid, binding, env)

    data_options = [
      %{variable: "row_data", columns: ["x", "y"]},
      %{variable: "column_data", columns: ["x", "y"]}
    ]

    assert_broadcast_event(widget, "set_available_data", %{
      "data_options" => ^data_options,
      "fields" => %{
        "data_variable" => "row_data",
        "x_field" => "x",
        "y_field" => "y"
      }
    })
  end

  describe "code generation" do
    test "source for a basic bar plot with no optionals" do
      attrs = build_attrs(%{})

      assert ChartBuilder.to_source(attrs) == """
             VegaLite.new()
             |> VegaLite.data_from_values(data, only: ["a", "b"])
             |> VegaLite.mark(:bar)
             |> VegaLite.encode_field(:x, "a")
             |> VegaLite.encode_field(:y, "b")\
             """
    end

    test "source for a basic line plot with alias" do
      attrs = build_attrs(%{"vl_alias" => Vl}, %{"chart_type" => "line"})

      assert ChartBuilder.to_source(attrs) == """
             Vl.new()
             |> Vl.data_from_values(data, only: ["a", "b"])
             |> Vl.mark(:line)
             |> Vl.encode_field(:x, "a")
             |> Vl.encode_field(:y, "b")\
             """
    end

    test "bar plot with color and color type" do
      attrs = build_attrs(%{"color_field" => "c", "color_field_type" => "nominal"})

      assert ChartBuilder.to_source(attrs) == """
             VegaLite.new()
             |> VegaLite.data_from_values(data, only: ["a", "b", "c"])
             |> VegaLite.mark(:bar)
             |> VegaLite.encode_field(:x, "a")
             |> VegaLite.encode_field(:y, "b")
             |> VegaLite.encode_field(:color, "c", type: :nominal)\
             """
    end

    test "point plot with width x and y field types and color without type" do
      attrs =
        build_attrs(%{"width" => 300}, %{
          "chart_type" => "point",
          "x_field_type" => "nominal",
          "y_field_type" => "quantitative",
          "color_field" => "c"
        })

      assert ChartBuilder.to_source(attrs) == """
             VegaLite.new(width: 300)
             |> VegaLite.data_from_values(data, only: ["a", "b", "c"])
             |> VegaLite.mark(:point)
             |> VegaLite.encode_field(:x, "a", type: :nominal)
             |> VegaLite.encode_field(:y, "b", type: :quantitative)
             |> VegaLite.encode_field(:color, "c")\
             """
    end

    test "area plot with types and alias" do
      attrs =
        build_attrs(
          %{"width" => 600, "height" => 300, "vl_alias" => Vl},
          %{
            "chart_type" => "point",
            "x_field_type" => "ordinal",
            "y_field_type" => "quantitative",
            "color_field" => "c",
            "color_field_type" => "nominal"
          }
        )

      assert ChartBuilder.to_source(attrs) == """
             Vl.new(width: 600, height: 300)
             |> Vl.data_from_values(data, only: ["a", "b", "c"])
             |> Vl.mark(:point)
             |> Vl.encode_field(:x, "a", type: :ordinal)
             |> Vl.encode_field(:y, "b", type: :quantitative)
             |> Vl.encode_field(:color, "c", type: :nominal)\
             """
    end

    test "area plot with aggregate and alias" do
      attrs =
        build_attrs(
          %{"width" => 600, "height" => 300, "vl_alias" => Vl},
          %{
            "chart_type" => "point",
            "x_field_type" => "ordinal",
            "y_field_aggregate" => "mean",
            "color_field" => "c",
            "color_field_type" => "nominal"
          }
        )

      assert ChartBuilder.to_source(attrs) == """
             Vl.new(width: 600, height: 300)
             |> Vl.data_from_values(data, only: ["a", "b", "c"])
             |> Vl.mark(:point)
             |> Vl.encode_field(:x, "a", type: :ordinal)
             |> Vl.encode_field(:y, "b", aggregate: :mean)
             |> Vl.encode_field(:color, "c", type: :nominal)\
             """
    end

    test "simple plot with title" do
      attrs = build_attrs(%{"chart_title" => "Chart Title"}, %{"chart_type" => "point"})

      assert ChartBuilder.to_source(attrs) == """
             VegaLite.new(title: "Chart Title")
             |> VegaLite.data_from_values(data, only: ["a", "b"])
             |> VegaLite.mark(:point)
             |> VegaLite.encode_field(:x, "a")
             |> VegaLite.encode_field(:y, "b")\
             """
    end

    test "simple plot with aggregate count" do
      attrs = build_attrs(%{"y_field" => "__count__"})

      assert ChartBuilder.to_source(attrs) == """
             VegaLite.new()
             |> VegaLite.data_from_values(data, only: ["a"])
             |> VegaLite.mark(:bar)
             |> VegaLite.encode_field(:x, "a")
             |> VegaLite.encode(:y, aggregate: :count)\
             """
    end
  end

  defp build_attrs(root_attrs \\ %{}, layer_attrs) do
    root_attrs = Map.merge(@root, root_attrs)
    layer_attrs = Map.merge(@layer, layer_attrs)
    Map.put(root_attrs, "layers", [layer_attrs])
  end
end
