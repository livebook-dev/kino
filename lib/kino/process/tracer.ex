defmodule Kino.Process.Tracer do
  @moduledoc false

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def get_trace_events(tracer) do
    GenServer.call(tracer, :get_trace_events)
  end

  @impl true
  def init(_) do
    {:ok, []}
  end

  @impl true
  def handle_call(:get_trace_events, _from, trace_events) do
    {:reply, trace_events, trace_events}
  end

  @impl true
  def handle_info({:seq_trace, _, {:send, _, from, to, message}, timestamp}, trace_events) do
    new_event = %{
      type: :send,
      timestamp: timestamp,
      from: from,
      to: to,
      message: message
    }

    {:noreply, [new_event | trace_events]}
  end

  def handle_info(_ignored_event, trace_events) do
    {:noreply, trace_events}
  end
end
