defmodule Kino.SubscriptionManagerTest do
  use ExUnit.Case, async: true

  alias Kino.SubscriptionManager

  test "subscribe/3 subscribes to events and attaches custom tag" do
    SubscriptionManager.subscribe("topic1", self(), :tag)

    event = %{type: :ping}
    send(SubscriptionManager, {:event, "topic1", event})

    assert_receive {:tag, ^event}
  end

  test "unsubscribe/3 unsubscribes the given process from a topic" do
    SubscriptionManager.subscribe("topic1", self(), :tag1)
    SubscriptionManager.subscribe("topic2", self(), :tag2)

    SubscriptionManager.unsubscribe("topic1", self())

    event = %{type: :ping}
    send(SubscriptionManager, {:event, "topic1", event})
    send(SubscriptionManager, {:event, "topic2", event})

    assert_receive {:tag2, ^event}
    refute_received {:tag1, ^event}
  end

  test "{:clear_topic, topic} removes all subscribers for the given topic" do
    SubscriptionManager.subscribe("topic1", self(), :tag1)
    SubscriptionManager.subscribe("topic2", self(), :tag2)

    send(SubscriptionManager, {:clear_topic, "topic1"})

    event = %{type: :ping}
    send(SubscriptionManager, {:event, "topic1", event})
    send(SubscriptionManager, {:event, "topic2", event})

    assert_receive {:tag2, ^event}
    refute_received {:tag1, ^event}
  end

  test "stream/1 returns event feed" do
    spawn(fn ->
      Process.sleep(1)
      send(SubscriptionManager, {:event, "topic1", {:ping, 1}})
      send(SubscriptionManager, {:event, "topic1", {:ping, 2}})
    end)

    events = "topic1" |> SubscriptionManager.stream() |> Enum.take(2)
    assert events == [{:ping, 1}, {:ping, 2}]
  end

  test "stream/1 halts when the topic is cleared" do
    spawn(fn ->
      Process.sleep(1)
      send(SubscriptionManager, {:event, "topic1", {:ping, 1}})
      send(SubscriptionManager, {:clear_topic, "topic1"})
    end)

    events = "topic1" |> SubscriptionManager.stream() |> Enum.to_list()
    assert events == [{:ping, 1}]
  end
end
