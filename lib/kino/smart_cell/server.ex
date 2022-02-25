defmodule Kino.SmartCell.Server do
  @moduledoc false

  require Logger

  import Kino.Utils, only: [has_function?: 3]

  alias Kino.JS.Live.Context

  def start_link(module, ref, attrs, target_pid) do
    case :proc_lib.start_link(__MODULE__, :init, [module, ref, attrs, target_pid]) do
      {:error, error} ->
        {:error, error}

      {:ok, pid, source} ->
        {:ok, pid,
         %{
           js_view: %{
             ref: ref,
             pid: pid,
             assets: module.__assets_info__()
           },
           source: source
         }}
    end
  end

  def broadcast_event(ctx, event, payload) do
    ref = ctx.__private__.ref
    Kino.Bridge.broadcast("js_live", ref, {:event, event, payload, %{ref: ref}})
    :ok
  end

  def init(module, ref, attrs, target_pid) do
    ctx = Context.new()
    ctx = put_in(ctx.__private__[:ref], ref)

    {:ok, ctx} =
      if has_function?(module, :init, 2) do
        module.init(attrs, ctx)
      else
        {:ok, ctx}
      end

    attrs = module.to_attrs(ctx)
    source = module.to_source(attrs)

    ctx = put_in(ctx.__private__[:attrs], attrs)

    :proc_lib.init_ack({:ok, self(), source})

    state = %{module: module, ctx: ctx, target_pid: target_pid, attrs: attrs}
    :gen_server.enter_loop(__MODULE__, [], state)
  end

  def handle_info({:connect, pid, %{origin: origin}}, state) do
    ctx = %{state.ctx | origin: origin}
    {:ok, data, ctx} = state.module.handle_connect(ctx)
    ctx = %{ctx | origin: nil}

    Kino.Bridge.send(pid, {:connect_reply, data, %{ref: state.ctx.__private__.ref}})

    {:noreply, maybe_send_update(%{state | ctx: ctx})}
  end

  def handle_info({:event, event, payload, %{origin: origin}}, state) do
    ctx = %{state.ctx | origin: origin}
    {:noreply, ctx} = state.module.handle_event(event, payload, ctx)
    ctx = %{ctx | origin: nil}

    {:noreply, maybe_send_update(%{state | ctx: ctx})}
  end

  def handle_info(msg, state) do
    apply_handle_info(msg, state)
  end

  def terminate(reason, state) do
    if has_function?(state.module, :terminate, 2) do
      state.module.terminate(reason, state.ctx)
    end

    :ok
  end

  defp apply_handle_info(msg, state) do
    state =
      if has_function?(state.module, :handle_info, 2) do
        {:noreply, ctx} = state.module.handle_info(msg, state.ctx)
        maybe_send_update(%{state | ctx: ctx})
      else
        Logger.error(
          "received message in #{inspect(__MODULE__)}, but no handle_info/2 was defined in #{inspect(state.module)}"
        )

        state
      end

    {:noreply, state}
  end

  defp maybe_send_update(state) do
    attrs = state.module.to_attrs(state.ctx)

    if attrs == state.attrs do
      state
    else
      source = state.module.to_source(attrs)

      send(
        state.target_pid,
        {:runtime_smart_cell_update, state.ctx.__private__.ref, attrs, source}
      )

      %{state | attrs: attrs}
    end
  end
end
