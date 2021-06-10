defmodule Kino.VegaLiteTest do
  use ExUnit.Case, async: true

  alias VegaLite, as: Vl

  test "push/3 sends data point message to the client" do
    widget = start_widget()

    connect_self(widget)

    Kino.VegaLite.push(widget, %{x: 1, y: 1})
    assert_receive {:push, %{data: [%{x: 1, y: 1}], dataset: nil, window: nil}}
  end

  test "push/3 allows for specifying the dataset" do
    widget = start_widget()

    connect_self(widget)

    Kino.VegaLite.push(widget, %{x: 1, y: 1}, dataset: "points")
    assert_receive {:push, %{data: [%{x: 1, y: 1}], dataset: "points", window: nil}}
  end

  test "sends current data after initial connection" do
    widget = start_widget()
    Kino.VegaLite.push(widget, %{x: 1, y: 1})

    connect_self(widget)

    assert_receive {:push, %{data: [%{x: 1, y: 1}], dataset: nil, window: nil}}
  end

  test "does not send data outside of the specified window" do
    widget = start_widget()
    Kino.VegaLite.push(widget, %{x: 1, y: 1}, window: 1)
    Kino.VegaLite.push(widget, %{x: 2, y: 2}, window: 1)

    connect_self(widget)

    assert_receive {:push, %{data: [%{x: 2, y: 2}], dataset: nil, window: nil}}
  end

  test "push_many/3 sends multiple datapoints" do
    widget = start_widget()

    connect_self(widget)

    points = [%{x: 1, y: 1}, %{x: 2, y: 2}]
    Kino.VegaLite.push_many(widget, points)
    assert_receive {:push, %{data: ^points, dataset: nil, window: nil}}
  end

  test "clear/2 pushes empty data" do
    widget = start_widget()

    connect_self(widget)

    Kino.VegaLite.clear(widget)
    assert_receive {:push, %{data: [], dataset: nil, window: 0}}
  end

  test "periodically/4 evaluates the given callback in background until stopped" do
    widget = start_widget()

    connect_self(widget)

    Kino.VegaLite.periodically(widget, 1, 1, fn n ->
      if n < 3 do
        Kino.VegaLite.push(widget, %{x: n, y: n})
        {:cont, n + 1}
      else
        :halt
      end
    end)

    assert_receive {:push, %{data: [%{x: 1, y: 1}], dataset: nil, window: nil}}
    assert_receive {:push, %{data: [%{x: 2, y: 2}], dataset: nil, window: nil}}
    Process.sleep(5)
    refute_received {:push, _}
  end

  defp start_widget() do
    Vl.new()
    |> Vl.mark(:point)
    |> Vl.encode_field(:x, "x", type: :quantitative)
    |> Vl.encode_field(:y, "y", type: :quantitative)
    |> Kino.VegaLite.start()
  end

  defp connect_self(widget) do
    send(widget.pid, {:connect, self()})
    assert_receive {:connect_reply, %{} = _vl_spec}
  end
end
