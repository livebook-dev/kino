defmodule Kino.JS.LiveServer do
  @moduledoc false

  use GenServer

  require Logger

  alias Kino.JS.Live.Context

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  defdelegate cast(pid, term), to: GenServer

  defdelegate call(pid, term, timeout), to: GenServer

  def broadcast_event(ctx, event, payload) do
    ref = ctx.__private__.ref
    Kino.Bridge.broadcast("js_live", ref, {:event, event, payload, %{ref: ref}})
    :ok
  end

  @impl true
  def init({module, init_arg, ref}) do
    ctx = Context.new()
    ctx = put_in(ctx.__private__[:ref], ref)

    {:ok, ctx} =
      if has_function?(module, :init, 2) do
        module.init(init_arg, ctx)
      else
        {:ok, ctx}
      end

    {:ok, %{module: module, ctx: ctx}}
  end

  @impl true
  def handle_cast(msg, state) do
    {:noreply, ctx} = state.module.handle_cast(msg, state.ctx)
    {:noreply, %{state | ctx: ctx}}
  end

  @impl true
  def handle_call(msg, from, state) do
    {:reply, reply, ctx} = state.module.handle_call(msg, from, state.ctx)
    {:reply, reply, %{state | ctx: ctx}}
  end

  @impl true
  def handle_info({:connect, pid, %{origin: origin}}, state) do
    ctx = %{state.ctx | origin: origin}
    {:ok, data, ctx} = state.module.handle_connect(ctx)
    ctx = %{ctx | origin: nil}

    Kino.Bridge.send(pid, {:connect_reply, data, %{ref: state.ctx.__private__.ref}})

    {:noreply, %{state | ctx: ctx}}
  end

  def handle_info({:event, event, payload, %{origin: origin}}, state) do
    ctx = %{state.ctx | origin: origin}
    {:noreply, ctx} = state.module.handle_event(event, payload, ctx)
    ctx = %{ctx | origin: nil}

    {:noreply, %{state | ctx: ctx}}
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

    {:noreply, %{state | ctx: ctx}}
  end

  defp has_function?(module, function, arity) do
    Code.ensure_loaded?(module) and function_exported?(module, function, arity)
  end
end
