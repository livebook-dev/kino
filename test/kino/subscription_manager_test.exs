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

  test "subscribe/3 with :notify_clear" do
    SubscriptionManager.subscribe("topic1", self(), :tag1, notify_clear: true)
    SubscriptionManager.subscribe("topic2", self(), :tag2)

    send(SubscriptionManager, {:clear_topic, "topic1"})
    send(SubscriptionManager, {:clear_topic, "topic2"})

    assert_receive {:tag1, :topic_cleared, "topic1"}
    refute_receive {:tag2, :topic_cleared, "topic2"}
  end
end
