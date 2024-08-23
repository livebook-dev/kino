defmodule Kino.Process.Tracer do
  @moduledoc false

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def get_trace_info(tracer) do
    GenServer.call(tracer, :get_trace_info, :infinity)
  end

  @impl true
  def init(_) do
    {:ok, %{raw_trace_events: [], process_labels: %{}}}
  end

  @impl true
  def handle_call(:get_trace_info, _from, trace_info) do
    {:reply, trace_info, trace_info}
  end

  @impl true
  def handle_info({:seq_trace, _, {:send, _, from, to, message}, timestamp}, trace_info) do
    new_event = %{
      type: :send,
      timestamp: timestamp,
      from: from,
      to: to,
      message: message
    }

    trace_events = [new_event | trace_info.raw_trace_events]

    process_labels =
      trace_info.process_labels
      |> put_new_label(from)
      |> put_new_label(to)

    {:noreply, %{trace_info | raw_trace_events: trace_events, process_labels: process_labels}}
  end

  def handle_info(_ignored_event, trace_events) do
    {:noreply, trace_events}
  end

  defp put_new_label(process_labels, pid) do
    Map.put_new_lazy(process_labels, pid, fn -> get_label(pid) end)
  end

  # :proc_lib.get_label/1 was added in OTP 27
  if Code.ensure_loaded?(:proc_lib) and function_exported?(:proc_lib, :get_label, 1) do
    defp get_label(pid), do: :proc_lib.get_label(pid)
  else
    defp get_label(_pid), do: :undefined
  end
end
