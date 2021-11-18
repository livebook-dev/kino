defmodule Kino.ControlsTest do
  use ExUnit.Case, async: true

  describe "new/1" do
    test "raises an error when control misses a required key" do
      assert_raise ArgumentError,
                   "invalid control specification: %{type: :button}",
                   fn ->
                     Kino.Controls.new([%{type: :button}])
                   end
    end

    test "raises an error on multiple keyboard controls" do
      assert_raise ArgumentError,
                   "controls may include only one :keyboard item",
                   fn ->
                     Kino.Controls.new([
                       %{type: :keyboard, events: [:keyup]},
                       %{type: :keyboard, events: [:keydown]}
                     ])
                   end
    end
  end

  @controls [
    %{type: :keyboard, events: [:keyup, :keydown]},
    %{type: :button, event: :hello, label: "Hello"}
  ]

  describe "connecting" do
    test "connect reply contains the defined controls" do
      widget = Kino.Controls.new(@controls)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply, %{controls: @controls}}
    end
  end

  describe "subscribe/1" do
    test "subscriber receives client join and leave" do
      widget = Kino.Controls.new(@controls)

      Kino.Controls.subscribe(widget)

      client_pid =
        spawn(fn ->
          connect_self(widget)
        end)

      assert_receive {:control_event, %{type: :client_join, origin: ^client_pid}}
      assert_receive {:control_event, %{type: :client_leave, origin: ^client_pid}}
    end

    test "subscriber receives client events" do
      widget = Kino.Controls.new(@controls)

      Kino.Controls.subscribe(widget)

      client_pid =
        spawn(fn ->
          connect_self(widget)
          send(widget.pid, {:event, %{type: :keydown, origin: self(), key: "u"}})
        end)

      assert_receive {:control_event, %{type: :keydown, origin: ^client_pid, key: "u"}}
    end
  end

  describe "unsubscribe/1" do
    test "cancells subscription" do
      widget = Kino.Controls.new(@controls)

      Kino.Controls.subscribe(widget)
      Kino.Controls.unsubscribe(widget)

      spawn(fn ->
        connect_self(widget)
      end)

      refute_receive {:control_event, _}
    end
  end

  defp connect_self(widget) do
    send(widget.pid, {:connect, self()})
    assert_receive {:connect_reply, %{}}
  end
end
