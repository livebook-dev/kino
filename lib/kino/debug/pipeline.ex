defmodule Kino.Debug.Pipeline do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/debug_pipeline"
  use Kino.JS.Live

  def new(sources, results, wrapped_funs, dbg_id, dbg_location_info) do
    result_frame = Kino.Frame.new()

    ui =
      Kino.JS.Live.new(
        __MODULE__,
        {sources, results, wrapped_funs, dbg_id, dbg_location_info, result_frame}
      )

    Kino.Layout.grid([ui, result_frame])
  end

  @impl true
  def init({sources, results, wrapped_funs, dbg_id, dbg_location_info, result_frame}, ctx) do
    Kino.Debug.register_dbg_handler!(dbg_id)

    funs = [nil | wrapped_funs.()]

    items =
      [sources, results, funs]
      |> Enum.zip()
      |> Enum.with_index(fn {source, result, fun}, idx ->
        %{id: idx, source: source, result: result, fun: fun, enabled: true}
      end)

    %{id: last_id} = List.last(items)

    {:ok,
     ctx
     |> assign(
       items: items,
       funs: funs,
       dbg_location_info: dbg_location_info,
       result_frame: result_frame,
       selected_id: last_id,
       errored_id: nil,
       error: nil,
       call_count: 1,
       changed?: false
     )
     |> update_result_frame()}
  end

  @impl true
  def handle_connect(ctx) do
    items = Enum.map(ctx.assigns.items, &Map.take(&1, [:id, :source, :enabled]))

    {:ok,
     %{
       dbg_location_info: ctx.assigns.dbg_location_info,
       items: items,
       selected_id: ctx.assigns.selected_id,
       errored_id: ctx.assigns.errored_id,
       error: ctx.assigns.error,
       call_count: ctx.assigns.call_count,
       changed: ctx.assigns.changed?
     }, ctx}
  end

  @impl true
  def handle_event("select_item", %{"id" => id}, ctx) do
    item = Enum.find(ctx.assigns.items, &(&1.id == id))

    ctx =
      if item.enabled do
        broadcast_event(ctx, "item_selected", %{"id" => id})
        ctx |> assign(selected_id: id) |> update_result_frame()
      else
        ctx
      end

    {:noreply, ctx}
  end

  def handle_event("update_enabled", %{"id" => id, "enabled" => enabled}, ctx) do
    index = Enum.find_index(ctx.assigns.items, &(&1.id == id))

    ctx =
      if id == ctx.assigns.selected_id and not enabled do
        prev_id = previous_enabled_id(ctx.assigns.items, id)
        assign(ctx, selected_id: prev_id)
      else
        ctx
      end

    items = put_in(ctx.assigns.items, [Access.at(index), :enabled], enabled)

    changed? = changed?(items)
    ctx = assign(ctx, changed?: changed?)

    broadcast_event(ctx, "enabled_updated", %{
      "id" => id,
      "enabled" => enabled,
      "selected_id" => ctx.assigns.selected_id,
      "changed" => changed?
    })

    ctx = handle_items_change(ctx, items)

    {:noreply, update_result_frame(ctx)}
  end

  def handle_event("move_item", %{"id" => id, "index" => index}, ctx) do
    current_index = Enum.find_index(ctx.assigns.items, &(&1.id == id))
    {item, items} = List.pop_at(ctx.assigns.items, current_index)
    items = List.insert_at(items, index, item)

    changed? = changed?(items)
    ctx = assign(ctx, changed?: changed?)

    broadcast_event(ctx, "item_moved", %{"id" => id, "index" => index, "changed" => changed?})

    ctx =
      if item.enabled do
        handle_items_change(ctx, items)
      else
        assign(ctx, items: items)
      end

    {:noreply, update_result_frame(ctx)}
  end

  def handle_event("source_request", %{}, ctx) do
    source = to_source(ctx.assigns.items)
    send_event(ctx, ctx.origin, "source_reply", %{"source" => source})
    {:noreply, ctx}
  end

  @impl true
  def handle_info(:dbg_call, ctx) do
    ctx = update(ctx, :call_count, &(&1 + 1))
    broadcast_event(ctx, "call_count_updated", %{"call_count" => ctx.assigns.call_count})
    {:noreply, ctx}
  end

  defp handle_items_change(ctx, items) do
    id =
      ctx.assigns.items
      |> Enum.zip(items)
      |> Enum.find_value(nil, fn
        {item, item} -> nil
        {_old, new} -> new.id
      end)

    if below_errored_item?(items, ctx.assigns.errored_id, id) do
      assign(ctx, items: items)
    else
      {items, errored_id, error} =
        case reevaluate_changed(items, id) do
          {:ok, items} -> {items, nil, nil}
          {:error, items, errored_id, error} -> {items, errored_id, error}
        end

      selected_id =
        if(errored_id, do: previous_enabled_id(items, errored_id), else: ctx.assigns.selected_id)

      ctx = assign(ctx, items: items, error: error)

      if errored_id != ctx.assigns.errored_id or selected_id != ctx.assigns.selected_id do
        ctx = assign(ctx, errored_id: errored_id, selected_id: selected_id)

        broadcast_event(ctx, "set_errored", %{
          "id" => errored_id,
          "error" => error,
          "selected_id" => selected_id
        })

        ctx
      else
        ctx
      end
    end
  end

  defp previous_enabled_id(items, id) do
    items
    |> Enum.take_while(&(&1.id != id))
    |> Enum.reverse()
    |> Enum.find_value(fn item -> item.enabled && item.id end)
  end

  defp below_errored_item?(_items, nil, _id), do: false

  defp below_errored_item?(items, errored_id, id) do
    ids_with_idx =
      items
      |> Enum.with_index()
      |> Map.new(fn {item, idx} -> {item.id, idx} end)

    ids_with_idx[errored_id] < ids_with_idx[id]
  end

  defp reevaluate_changed([head_item | items], changed_id) do
    {prev_items, items} = Enum.split_while(items, &(&1.id != changed_id))

    {unchanged_items, result} =
      Enum.reduce_while(prev_items, {[head_item], head_item.result}, fn
        %{id: ^changed_id}, acc ->
          {:halt, acc}

        item, {unchanged_items, result} ->
          result = if item.enabled, do: item.result, else: result
          {:cont, {[item | unchanged_items], result}}
      end)

    reevaluate(items, {unchanged_items, result})
  end

  defp reevaluate([], {new_items, _result}), do: {:ok, Enum.reverse(new_items)}

  defp reevaluate([%{enabled: false} = item | items], {new_items, result}) do
    reevaluate(items, {[item | new_items], result})
  end

  defp reevaluate([item | items], {new_items, result}) do
    try do
      result = item.fun.(result)
      item = %{item | result: result}
      reevaluate(items, {[item | new_items], result})
    catch
      kind, error ->
        formatted_error = format_error(kind, error, __STACKTRACE__)
        {:error, Enum.reverse([item | new_items], items), item.id, formatted_error}
    end
  end

  defp format_error(kind, error, stacktrace) do
    stacktrace = prune_stacktrace(stacktrace)
    formatted = Exception.format(kind, error, stacktrace)
    String.replace_trailing(formatted, "\n", "")
  end

  defp prune_stacktrace(stacktrace) do
    stacktrace
    |> Enum.reverse()
    |> Enum.drop_while(&(elem(&1, 0) != __MODULE__))
    |> Enum.drop_while(&(elem(&1, 0) == __MODULE__))
    # The anonymous function call and definition
    |> Enum.drop(2)
    |> Enum.reverse()
  end

  defp update_result_frame(ctx) do
    item = Enum.find(ctx.assigns.items, &(&1.id == ctx.assigns.selected_id))
    Kino.Frame.render(ctx.assigns.result_frame, item.result)
    ctx
  end

  defp changed?(items) do
    items
    |> Enum.reduce_while(0, fn
      %{id: id, enabled: true}, id -> {:cont, id + 1}
      _item, _acc -> {:halt, nil}
    end)
    |> is_nil()
  end

  defp to_source(items) do
    lines = for item <- items, item.enabled, do: item.source
    Enum.join(lines, "\n")
  end
end
