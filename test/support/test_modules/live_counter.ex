defmodule Kino.TestModules.LiveCounter do
  use Kino.JS
  use Kino.JS.Live

  def new(count) do
    Kino.JS.Live.new(__MODULE__, count)
  end

  def bump(kino, by \\ 1) do
    Kino.JS.Live.cast(kino, {:bump, by})
  end

  def read(kino) do
    Kino.JS.Live.call(kino, :read)
  end

  @impl true
  def init(count, ctx) do
    {:ok, assign(ctx, count: count)}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, ctx.assigns.count, ctx}
  end

  @impl true
  def handle_event("bump", %{"by" => by}, ctx) do
    {:noreply, bump_count(ctx, by)}
  end

  @impl true
  def handle_cast({:bump, by}, ctx) do
    {:noreply, bump_count(ctx, by)}
  end

  @impl true
  def handle_call(:read, _from, ctx) do
    {:reply, ctx.assigns.count, ctx}
  end

  @impl true
  def handle_info({:ping, from}, ctx) do
    send(from, :pong)
    {:noreply, ctx}
  end

  defp bump_count(ctx, by) do
    broadcast_event(ctx, "bump", %{by: by})
    update(ctx, :count, &(&1 + by))
  end

  asset "main.js" do
    """
    export function init(ctx, data) {
      console.log(data);
    }
    """
  end
end
