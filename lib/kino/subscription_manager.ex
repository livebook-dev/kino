defmodule Kino.SubscriptionManager do
  @moduledoc false

  # The primary process responsible for subscribing to
  # and broadcasting input/control events.

  use GenServer

  @name __MODULE__

  @type state :: %{
          topic_with_subscribers: %{topic() => list({pid(), info()})},
          pid_with_topics: %{pid() => list(topic())}
        }

  @type topic :: term()
  @type info :: %{tag: term(), notify_clear: boolean()}

  def cross_node_name() do
    {@name, node()}
  end

  @doc """
  Starts the manager.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @doc """
  Subscribes the given process to events under `topic`.

  All events are sent as `{tag, info}`, where `tag` is
  the given term used for identifying the messages.

  ## Options

    * `:notify_clear` - when set to true, sends
      `{tag, :topic_cleared, topic}` when topic is removed
  """
  @spec subscribe(term(), pid(), term(), keyword()) :: :ok
  def subscribe(topic, pid, tag, opts \\ []) do
    notify_clear = Keyword.get(opts, :notify_clear, false)
    info = %{tag: tag, notify_clear: notify_clear}
    GenServer.cast(@name, {:subscribe, topic, pid, info})
  end

  @doc """
  Unsubscribes the given process from events under `topic`.
  """
  @spec unsubscribe(term(), pid()) :: :ok
  def unsubscribe(topic, pid) do
    GenServer.cast(@name, {:unsubscribe, topic, pid})
  end

  @impl true
  def init(_opts) do
    {:ok, %{topic_with_subscribers: %{}, pid_with_topics: %{}}}
  end

  @impl true
  def handle_cast({:subscribe, topic, pid, info}, state) do
    Process.monitor(pid)

    state =
      update_in(state.topic_with_subscribers[topic], fn
        nil -> [{pid, info}]
        subscribers -> [{pid, info} | remove_pid(subscribers, pid)]
      end)

    state =
      update_in(state.pid_with_topics[pid], fn
        nil -> [topic]
        topics -> if topic in topics, do: topics, else: [topic | topics]
      end)

    {:noreply, state}
  end

  def handle_cast({:unsubscribe, topic, pid}, state) do
    state =
      state
      |> remove_topic_subscriber(topic, pid)
      |> remove_pid_topic(pid, topic)

    {:noreply, state}
  end

  @impl true
  def handle_info({:event, topic, event}, state) do
    for {pid, info} <- state.topic_with_subscribers[topic] || [] do
      send(pid, {info.tag, event})
    end

    {:noreply, state}
  end

  def handle_info({:clear_topic, topic}, state) do
    {subscribers, state} = pop_in(state.topic_with_subscribers[topic])

    state =
      Enum.reduce(subscribers || [], state, fn {pid, info}, state ->
        if info.notify_clear do
          send(pid, {info.tag, :topic_cleared, topic})
        end

        remove_pid_topic(state, pid, topic)
      end)

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {topics, state} = pop_in(state.pid_with_topics[pid])

    state =
      Enum.reduce(topics || [], state, fn topic, state ->
        remove_topic_subscriber(state, topic, pid)
      end)

    {:noreply, state}
  end

  defp remove_topic_subscriber(state, topic, pid) do
    case pop_in(state.topic_with_subscribers[topic]) do
      {nil, state} ->
        state

      {[{^pid, _tag}], state} ->
        state

      {subscribers, state} ->
        put_in(state.topic_with_subscribers[topic], remove_pid(subscribers, pid))
    end
  end

  defp remove_pid_topic(state, pid, topic) do
    case pop_in(state.pid_with_topics[pid]) do
      {nil, state} -> state
      {[^topic], state} -> state
      {topics, state} -> put_in(state.pid_with_topics[pid], topics -- [topic])
    end
  end

  defp remove_pid(subscribers, pid) do
    Enum.reject(subscribers, &match?({^pid, _info}, &1))
  end
end
