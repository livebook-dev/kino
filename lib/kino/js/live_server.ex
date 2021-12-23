defmodule Kino.JS.LiveServer do
  @moduledoc false

  @doc false
  use GenServer

  require Logger

  alias Kino.JS.Live.Context

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc false
  defdelegate cast(pid, term), to: GenServer

  @doc false
  defdelegate call(pid, term, timeout), to: GenServer

  @impl true
  def init({module, init_arg}) do
    ctx = Context.new()

    {:ok, ctx} =
      if has_function?(module, :init, 2) do
        module.init(init_arg, ctx)
      else
        {:ok, ctx}
      end

    {:ok, %{module: module, client_pids: [], client_monitor_refs: [], ctx: ctx}}
  end

  @impl true
  def handle_cast(msg, state) do
    {:noreply, ctx} = state.module.handle_cast(msg, state.ctx)
    {:noreply, apply_ctx(state, ctx)}
  end

  @impl true
  def handle_call(msg, from, state) do
    {:reply, reply, ctx} = state.module.handle_call(msg, from, state.ctx)
    {:reply, reply, apply_ctx(state, ctx)}
  end

  @impl true
  def handle_info({:connect, pid}, state) do
    ref = Process.monitor(pid)

    state = update_in(state.client_pids, &[pid | &1])
    state = update_in(state.client_monitor_refs, &[ref | &1])

    {:ok, data, ctx} = state.module.handle_connect(state.ctx)
    send(pid, {:connect_reply, data})

    {:noreply, apply_ctx(state, ctx)}
  end

  def handle_info({:event, event, payload}, state) do
    {:noreply, ctx} = state.module.handle_event(event, payload, state.ctx)
    {:noreply, apply_ctx(state, ctx)}
  end

  def handle_info({:DOWN, ref, :process, pid, _reason} = msg, state) do
    if ref in state.client_monitor_refs do
      state = update_in(state.client_pids, &List.delete(&1, pid))
      state = update_in(state.client_monitor_refs, &List.delete(&1, ref))
      {:noreply, state}
    else
      apply_handle_info(msg, state)
    end
  end

  def handle_info(msg, state) do
    apply_handle_info(msg, state)
  end

  @impl true
  def terminate(reason, state) do
    if has_function?(state.module, :terminate, 2) do
      state.module.terminate(reason, state.ctx)
    end

    :ok
  end

  defp apply_ctx(state, ctx) do
    for {event, payload} <- Enum.reverse(ctx.events),
        pid <- state.client_pids,
        do: send(pid, {:event, event, payload})

    ctx = %{ctx | events: []}
    %{state | ctx: ctx}
  end

  defp apply_handle_info(msg, state) do
    {:noreply, ctx} =
      if has_function?(state.module, :handle_info, 2) do
        state.module.handle_info(msg, state.ctx)
      else
        Logger.error(
          "received message in #{inspect(__MODULE__)}, but no handle_info/2 was defined in #{inspect(state.module)}"
        )

        {:noreply, state.ctx}
      end

    {:noreply, apply_ctx(state, ctx)}
  end

  defp has_function?(module, function, arity) do
    Code.ensure_loaded?(module) and function_exported?(module, function, arity)
  end
end
