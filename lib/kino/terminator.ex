defmodule Kino.Terminator do
  @moduledoc false

  # A process responsible for shutting down processes.

  use GenServer

  @name __MODULE__

  def cross_node_name() do
    {@name, node()}
  end

  @doc """
  Starts a Kino process to be shutdown by the terminator.
  """
  def start_child({mod, fun, args}, parent, gl) do
    # We switch the group leader, so that the newly started
    # process gets the same group leader as the caller
    initial_gl = Process.group_leader()

    Process.group_leader(self(), gl)

    try do
      {resp, pid} =
        case apply(mod, fun, args) do
          {:ok, pid} = resp -> {resp, pid}
          {:ok, pid, _info} = resp -> {resp, pid}
          resp -> {resp, nil}
        end

      if pid do
        terminator = cross_node_name()

        Kino.Bridge.reference_object(pid, parent)

        with {:request_error, :terminated} <-
               Kino.Bridge.monitor_object(pid, terminator, {:terminate, pid}, ack?: true) do
          # If the group leader terminated, it is not going to monitor
          # the process as we expect, so we terminate it immediately
          send(terminator, {:terminate, pid})
        end
      end

      resp
    after
      Process.group_leader(self(), initial_gl)
    end
  end

  @doc """
  Starts a task that will terminate the parent in case of crashes.
  """
  def start_task(parent, fun) do
    Task.start_link(fn ->
      GenServer.call(@name, {:monitor, self(), parent}, :infinity)
      fun.()
    end)
  end

  @doc """
  Starts the terminator.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:monitor, pid, parent}, _from, state) do
    _ref = Process.monitor(pid)
    {:reply, :ok, Map.put(state, pid, parent)}
  end

  @impl true
  def handle_info({{:terminate, pid}, reply_to, reply_as}, state) do
    DynamicSupervisor.terminate_child(Kino.DynamicSupervisor, pid)
    send(reply_to, reply_as)
    {:noreply, Map.delete(state, pid)}
  end

  def handle_info({:terminate, pid}, state) do
    DynamicSupervisor.terminate_child(Kino.DynamicSupervisor, pid)
    {:noreply, Map.delete(state, pid)}
  end

  @impl true
  def handle_info({:DOWN, _, _, pid, reason}, state) do
    {parent, state} = Map.pop(state, pid)

    if is_pid(parent) and abnormal?(reason) do
      Process.exit(parent, reason)
    end

    {:noreply, state}
  end

  defp abnormal?(:normal), do: false
  defp abnormal?(:shutdown), do: false
  defp abnormal?({:shutdown, _}), do: false
  defp abnormal?(_), do: true
end
