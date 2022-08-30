defmodule Kino.Debug.Default do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/debug_default"
  use Kino.JS.Live

  def new(source, result, dbg_id, dbg_same_file, dbg_line) do
    ui = Kino.JS.Live.new(__MODULE__, {source, dbg_id, dbg_same_file, dbg_line})
    Kino.Layout.grid([ui, result], boxed: true, gap: 8)
  end

  @impl true
  def init({source, dbg_id, dbg_same_file, dbg_line}, ctx) do
    Kino.Debug.register_dbg_handler!(dbg_id)

    {:ok,
     assign(ctx,
       source: source,
       dbg_same_file: dbg_same_file,
       dbg_line: dbg_line,
       call_count: 1
     )}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok,
     %{
       dbg_same_file: ctx.assigns.dbg_same_file,
       dbg_line: ctx.assigns.dbg_line,
       call_count: ctx.assigns.call_count,
       source: ctx.assigns.source
     }, ctx}
  end

  @impl true
  def handle_info(:dbg_call, ctx) do
    ctx = update(ctx, :call_count, &(&1 + 1))
    broadcast_event(ctx, "call_count_updated", %{"call_count" => ctx.assigns.call_count})
    {:noreply, ctx}
  end
end
