defmodule Kino.JS.LiveTest do
  use Kino.LivebookCase, async: true

  import KinoTest.JS.Live

  alias Kino.TestModules.LiveCounter

  # Integration tests covering callback paths
  describe "LiveCounter" do
    test "handle_connect/1" do
      widget = LiveCounter.new(0)
      LiveCounter.bump(widget, 1)
      count = connect(widget)
      assert count == 1
    end

    test "handle_cast/2 with event broadcast" do
      widget = LiveCounter.new(0)
      LiveCounter.bump(widget, 2)
      assert_broadcast_event(widget, "bump", %{by: 2})
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
      push_event(widget, "bump", %{"by" => 2})
      count = LiveCounter.read(widget)
      assert count == 2
    end
  end
end
