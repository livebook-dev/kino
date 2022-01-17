defmodule Kino.SubscriptionManager do
  @moduledoc false

  # The primary process responsible for subscribing to
  # and broadcasting input/control events.

  use GenServer

  @name __MODULE__

  @type state :: %{
          topic_with_subscribers: %{topic() => list({pid(), tag()})},
          pid_with_topics: %{pid() => list(topic())}
        }

  @type topic :: term()
  @type tag :: term()

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
  """
  @spec subscribe(term(), pid(), term()) :: :ok
  def subscribe(topic, pid, tag) do
    GenServer.cast(@name, {:subscribe, topic, pid, tag})
  end

  @doc """
  Unsubscribes the given process from events under `topic`.
  """
  @spec unsubscribe(term(), pid()) :: :ok
  def unsubscribe(topic, pid) do
    GenServer.cast(@name, {:unsubscribe, topic, pid})
  end

  @doc """
  Returns a `Stream` of events under `topic`.
  """
  @spec stream(term()) :: Enumerable.t()
  def stream(topic) do
    Stream.resource(
      fn ->
        tag = {:__stream__, make_ref()}
        subscribe(topic, self(), tag)
        tag
      end,
      fn tag ->
        receive do
          {^tag, event} -> {[event], tag}
          {^tag, :__topic_cleared__, ^topic} -> {:halt, tag}
        end
      end,
      fn _ref -> unsubscribe(topic, self()) end
    )
  end

  @impl true
  def init(_opts) do
    {:ok, %{topic_with_subscribers: %{}, pid_with_topics: %{}}}
  end

  @impl true
  def handle_cast({:subscribe, topic, pid, tag}, state) do
    Process.monitor(pid)

    state =
      update_in(state.topic_with_subscribers[topic], fn
        nil -> [{pid, tag}]
        subscribers -> [{pid, tag} | remove_pid(subscribers, pid)]
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
    for {pid, tag} <- state.topic_with_subscribers[topic] || [] do
      send(pid, {tag, event})
    end

    {:noreply, state}
  end

  def handle_info({:clear_topic, topic}, state) do
    {subscribers, state} = pop_in(state.topic_with_subscribers[topic])

    state =
      Enum.reduce(subscribers || [], state, fn {pid, tag}, state ->
        with {:__stream__, _ref} <- tag do
          send(pid, {tag, :__topic_cleared__, topic})
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
    Enum.reject(subscribers, &match?({^pid, _tag}, &1))
  end
end
