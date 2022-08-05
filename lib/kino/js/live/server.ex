defmodule Kino.JS.Live.Server do
  @moduledoc false

  use GenServer, restart: :temporary

  require Logger

  import Kino.Utils, only: [has_function?: 3]

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

  def send_event(ctx, client_id, event, payload) do
    ref = ctx.__private__.ref

    if pid = ctx.__private__.client_ids_with_pid[client_id] do
      Kino.Bridge.send(pid, {:event, event, payload, %{ref: ref}})
    end

    :ok
  end

  @impl true
  def init({module, init_arg, ref}) do
    {:ok, ctx, _opts} = call_init(module, init_arg, ref)
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
  def handle_info(msg, state) do
    case call_handle_info(msg, state.module, state.ctx) do
      {:ok, ctx} -> {:noreply, %{state | ctx: ctx}}
      :error -> {:noreply, state}
    end
  end

  @impl true
  def terminate(reason, state) do
    call_terminate(reason, state.module, state.ctx)
  end

  # Handlers shared with Kino.SmartCell.Server

  def call_init(module, init_arg, ref) do
    ctx = Context.new()
    ctx = put_in(ctx.__private__[:ref], ref)
    ctx = put_in(ctx.__private__[:client_ids_with_pid], %{})
    ctx = put_in(ctx.__private__[:monitors_with_client_id], %{})

    if has_function?(module, :init, 2) do
      case module.init(init_arg, ctx) do
        {:ok, ctx} -> {:ok, ctx, []}
        {:ok, ctx, opts} -> {:ok, ctx, opts}
      end
    else
      {:ok, ctx, []}
    end
  end

  def call_handle_info(msg, module, ctx)

  def call_handle_info({:connect, pid, %{origin: origin}}, module, ctx) do
    ctx = add_client(ctx, pid, origin)

    ctx = %{ctx | origin: origin}
    {:ok, data, ctx} = module.handle_connect(ctx)
    ctx = %{ctx | origin: nil}

    Kino.Bridge.send(pid, {:connect_reply, data, %{ref: ctx.__private__.ref}})

    {:ok, ctx}
  end

  def call_handle_info({:event, event, payload, %{origin: origin}}, module, ctx) do
    ctx = %{ctx | origin: origin}
    {:noreply, ctx} = module.handle_event(event, payload, ctx)
    ctx = %{ctx | origin: nil}

    {:ok, ctx}
  end

  def call_handle_info({:ping, pid, term, _info}, _module, ctx) do
    Kino.Bridge.send(pid, {:pong, term, %{ref: ctx.__private__.ref}})

    {:ok, ctx}
  end

  def call_handle_info({:DOWN, ref, :process, _pid, _reason} = msg, module, ctx) do
    with :error <- remove_client(ctx, ref) do
      call_handle_info_fallback(msg, module, ctx)
    end
  end

  def call_handle_info(msg, module, ctx) do
    call_handle_info_fallback(msg, module, ctx)
  end

  def call_handle_info_fallback(msg, module, ctx) do
    if has_function?(module, :handle_info, 2) do
      {:noreply, ctx} = module.handle_info(msg, ctx)
      {:ok, ctx}
    else
      Logger.error(
        "received message in #{inspect(__MODULE__)}, but no handle_info/2 was defined in #{inspect(module)}"
      )

      :error
    end
  end

  def call_terminate(reason, module, ctx) do
    if has_function?(module, :terminate, 2) do
      module.terminate(reason, ctx)
    end

    :ok
  end

  defp add_client(ctx, pid, client_id) do
    if Map.has_key?(ctx.__private__.client_ids_with_pid, client_id) do
      ctx
    else
      monitor_ref = Kino.Bridge.monitor(pid)
      ctx = put_in(ctx.__private__.client_ids_with_pid[client_id], pid)
      put_in(ctx.__private__.monitors_with_client_id[monitor_ref], client_id)
    end
  end

  defp remove_client(ctx, monitor_ref) do
    {client_id, ctx} = pop_in(ctx.__private__.monitors_with_client_id[monitor_ref])

    if client_id do
      {_, ctx} = pop_in(ctx.__private__.client_ids_with_pid[client_id])
      {:ok, ctx}
    else
      :error
    end
  end
end
