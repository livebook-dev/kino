defmodule Kino.SmartCell.Server do
  @moduledoc false

  require Logger

  import Kino.Utils, only: [has_function?: 3]

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
           source: source,
           scan_binding: if(has_function?(module, :scan_binding, 2), do: &module.scan_binding/2)
         }}
    end
  end

  def init(module, ref, attrs, target_pid) do
    {:ok, ctx} = Kino.JS.Live.Server.call_init(module, attrs, ref)

    attrs = module.to_attrs(ctx)
    source = module.to_source(attrs)

    ctx = put_in(ctx.__private__[:attrs], attrs)

    :proc_lib.init_ack({:ok, self(), source})

    state = %{
      module: module,
      ctx: ctx,
      target_pid: target_pid,
      attrs: attrs,
      scan_binding_version: -1
    }

    :gen_server.enter_loop(__MODULE__, [], state)
  end

  def handle_info({:scan_binding_result, version, result}, state) do
    state =
      case result do
        _ignore when version <= state.scan_binding_version ->
          state

        {:error, error} ->
          Logger.error(
            "got error when running #{inspect(state.module)}.scan_binding/2, #{inspect(error)}"
          )

          state

        {:ok, data} ->
          ctx = state.module.scan_binding_continue(data, state.ctx)
          maybe_send_update(%{state | ctx: ctx, scan_binding_version: version})
      end

    {:noreply, state}
  end

  def handle_info(msg, state) do
    case Kino.JS.Live.Server.call_handle_info(msg, state.module, state.ctx) do
      {:ok, ctx} -> {:noreply, maybe_send_update(%{state | ctx: ctx})}
      :error -> {:noreply, state}
    end
  end

  def terminate(reason, state) do
    Kino.JS.Live.Server.call_terminate(reason, state.module, state.ctx)
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
