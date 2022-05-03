defmodule Kino.JS.LiveTest do
  use Kino.LivebookCase, async: true

  alias Kino.TestModules.LiveCounter

  # Integration tests covering callback paths
  describe "LiveCounter" do
    test "handle_connect/1" do
      kino = LiveCounter.new(0)
      LiveCounter.bump(kino, 1)
      count = connect(kino)
      assert count == 1
    end

    test "handle_cast/2 with event broadcast" do
      kino = LiveCounter.new(0)
      LiveCounter.bump(kino, 2)
      assert_broadcast_event(kino, "bump", %{by: 2})
    end

    test "handle_call/3" do
      kino = LiveCounter.new(0)
      LiveCounter.bump(kino, 1)
      count = LiveCounter.read(kino)
      assert count == 1
    end

    test "handle_info/2" do
      kino = LiveCounter.new(0)
      send(kino.pid, {:ping, self()})
      assert_receive :pong
    end

    test "handle_event/3" do
      kino = LiveCounter.new(0)
      # Simulate a client event
      push_event(kino, "bump", %{"by" => 2})
      count = LiveCounter.read(kino)
      assert count == 2
    end
  end

  test "server ping" do
    %{ref: ref} = kino = LiveCounter.new(0)
    send(kino.pid, {:ping, self(), :metadata, %{ref: ref}})
    assert_receive {:pong, :metadata, %{ref: ^ref}}
  end
end
