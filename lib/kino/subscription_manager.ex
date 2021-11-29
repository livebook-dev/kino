defmodule Kino.SubscriptionManager do
  @moduledoc false

  # The primary process responsible for subscribing to
  # and broadcasting input/control events.

  use GenServer

  @name __MODULE__

  @type state :: %{
          subscribers_by_topic: %{(topic :: term()) => {teraget :: pid(), receive_as :: term()}}
        }

  def cross_node_name() do
    {@name, node()}
  end

  @doc """
  Starts the manager
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @doc """
  Subscribes the given process to events under `topic`.

  All events are sent as `{:event, receive_as, info}`,
  where `receive_as` is the given term.
  """
  @spec subscribe(term(), pid(), term()) :: :ok
  def subscribe(topic, pid, receive_as) do
    GenServer.cast(@name, {:subscribe, topic, pid, receive_as})
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
    {:ok, %{subscribers_by_topic: %{}}}
  end

  @impl true
  def handle_cast({:subscribe, topic, pid, receive_as}, state) do
    Process.monitor(pid)

    state =
      update_in(state.subscribers_by_topic[topic], fn
        nil -> [{pid, receive_as}]
        subscribers -> [{pid, receive_as} | remove_pid(subscribers, pid)]
      end)

    {:noreply, state}
  end

  def handle_cast({:unsubscribe, topic, pid}, state) do
    state =
      update_in(state.subscribers_by_topic[topic], fn
        nil -> nil
        subscribers -> remove_pid(subscribers, pid)
      end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:event, topic, event}, state) do
    for {pid, receive_as} <- state.subscribers_by_topic[topic] || [] do
      send(pid, {:event, receive_as, event})
    end

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    subscribers_by_topic =
      state.subscribers_by_topic
      |> Enum.map(fn {topic, subscribers} -> {topic, remove_pid(subscribers, pid)} end)
      |> Enum.filter(&match?({_, []}, &1))
      |> Map.new()

    {:noreply, %{state | subscribers_by_topic: subscribers_by_topic}}
  end

  defp remove_pid(subscribers, pid) do
    Enum.reject(subscribers, &match?({^pid, _receive_as}, &1))
  end
end
