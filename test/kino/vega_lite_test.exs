defmodule Kino.VegaLiteTest do
  use Kino.LivebookCase, async: true

  import KinoTest.JS.Live

  alias VegaLite, as: Vl

  test "sends current data after initial connection" do
    widget = start_widget()
    Kino.VegaLite.push(widget, %{x: 1, y: 1})

    data = connect(widget)
    assert %{spec: %{}, datasets: [[nil, [%{x: 1, y: 1}]]]} = data
  end

  test "does not send data outside of the specified window" do
    widget = start_widget()
    Kino.VegaLite.push(widget, %{x: 1, y: 1}, window: 1)
    Kino.VegaLite.push(widget, %{x: 2, y: 2}, window: 1)

    data = connect(widget)
    assert %{spec: %{}, datasets: [[nil, [%{x: 2, y: 2}]]]} = data
  end

  test "push/3 sends data point message to the client" do
    widget = start_widget()

    Kino.VegaLite.push(widget, %{x: 1, y: 1})

    assert_broadcast_event(widget, "push", %{data: [%{x: 1, y: 1}], dataset: nil, window: nil})
  end

  test "push/3 allows for specifying the dataset" do
    widget = start_widget()

    Kino.VegaLite.push(widget, %{x: 1, y: 1}, dataset: "points")

    assert_broadcast_event(widget, "push", %{
      data: [%{x: 1, y: 1}],
      dataset: "points",
      window: nil
    })
  end

  test "push/3 converts keyword list to map" do
    widget = start_widget()

    Kino.VegaLite.push(widget, x: 1, y: 1)

    assert_broadcast_event(widget, "push", %{data: [%{x: 1, y: 1}], dataset: nil, window: nil})
  end

  test "push/3 raises if an invalid data type is given" do
    widget = start_widget()

    assert_raise Protocol.UndefinedError, ~r/"invalid"/, fn ->
      Kino.VegaLite.push(widget, "invalid")
    end
  end

  test "push_many/3 sends multiple datapoints" do
    widget = start_widget()

    points = [%{x: 1, y: 1}, %{x: 2, y: 2}]
    Kino.VegaLite.push_many(widget, points)

    assert_broadcast_event(widget, "push", %{data: ^points, dataset: nil, window: nil})
  end

  test "push_many/3 raises if an invalid data type is given" do
    widget = start_widget()

    assert_raise Protocol.UndefinedError, ~r/"invalid"/, fn ->
      Kino.VegaLite.push_many(widget, ["invalid"])
    end
  end

  test "clear/2 pushes empty data" do
    widget = start_widget()

    Kino.VegaLite.clear(widget)

    assert_broadcast_event(widget, "push", %{data: [], dataset: nil, window: 0})
  end

  test "periodically/4 evaluates the given callback in background until stopped" do
    widget = start_widget()

    parent = self()

    Kino.VegaLite.periodically(widget, 1, 1, fn n ->
      send(parent, {:ping, n})

      if n < 2 do
        {:cont, n + 1}
      else
        :halt
      end
    end)

    assert_receive {:ping, 1}
    assert_receive {:ping, 2}
    refute_receive {:ping, 3}, 5
  end

  defp start_widget() do
    Vl.new()
    |> Vl.mark(:point)
    |> Vl.encode_field(:x, "x", type: :quantitative)
    |> Vl.encode_field(:y, "y", type: :quantitative)
    |> Kino.VegaLite.new()
  end
end
