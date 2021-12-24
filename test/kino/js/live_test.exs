defmodule Kino.JS.LiveTest do
  use ExUnit.Case, async: true

  alias Kino.TestModules.LiveCounter

  # Integration tests covering callback paths
  describe "LiveCounter" do
    test "handle_connect/1" do
      widget = LiveCounter.new(0)
      LiveCounter.bump(widget, 1)
      count = connect_self(widget)
      assert count == 1
    end

    test "handle_cast/2 with event broadcast" do
      widget = LiveCounter.new(0)
      connect_self(widget)
      LiveCounter.bump(widget, 2)
      assert_receive {:event, "bump", %{by: 2}}
    end

    test "handle_call/3" do
      widget = LiveCounter.new(0)
      LiveCounter.bump(widget, 1)
      count = LiveCounter.read(widget)
      assert count == 1
    end

    test "handle_info/2" do
      widget = LiveCounter.new(0)
      send(widget.pid, {:ping, self()})
      assert_receive :pong
    end

    test "handle_event/3" do
      widget = LiveCounter.new(0)
      # Simulate a client event
      send(widget.pid, {:event, "bump", %{"by" => 2}, %{origin: self()}})
      count = LiveCounter.read(widget)
      assert count == 2
    end
  end

  defp connect_self(widget) do
    send(widget.pid, {:connect, self(), %{origin: self()}})
    assert_receive {:connect_reply, data}
    data
  end

  describe "assign/2" do
    test "stores value under the given key if it doesn't exist" do
      ctx = Kino.JS.Live.Context.new()
      assert %{assigns: %{count: 1}} = Kino.JS.Live.assign(ctx, count: 1)
    end

    test "overrides value if the given key already exists" do
      ctx = Kino.JS.Live.Context.new() |> Kino.JS.Live.assign(count: 1)
      assert %{assigns: %{count: 2}} = Kino.JS.Live.assign(ctx, count: 2)
    end
  end

  describe "update/3" do
    test "raises an error when nonexistent key is given" do
      ctx = Kino.JS.Live.Context.new()

      assert_raise KeyError, ~r/:count/, fn ->
        Kino.JS.Live.update(ctx, :count, &(&1 + 1))
      end
    end

    test "updates value with the given function" do
      ctx = Kino.JS.Live.Context.new() |> Kino.JS.Live.assign(count: 1)
      assert %{assigns: %{count: 2}} = Kino.JS.Live.update(ctx, :count, &(&1 + 1))
    end
  end
end
