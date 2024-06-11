defmodule Kino.Process.LabelTracer do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  def get_process_labels(pid) do
    GenServer.call(pid, :get_process_labels)
  end

  @impl true
  def init(_) do
    :erlang.trace(:all, true, [:call, {:tracer, self()}])
    :erlang.trace_pattern({Process, :set_label, 1}, true, [:local])
    {:ok, %{}}
  end

  @impl true
  def handle_info({:trace, pid, :call, {Process, :set_label, [process_label]}}, state) do
    state = Map.put(state, pid, process_label)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_process_labels, _from, state) do
    {:reply, state, state}
  end
end
