defmodule Kino.DataTable do
  @moduledoc """
  A kino for interactively viewing tabular data.

  The data must be a tabular data supported by `Table`.

  ## Examples

      data = [
        %{id: 1, name: "Elixir", website: "https://elixir-lang.org"},
        %{id: 2, name: "Erlang", website: "https://www.erlang.org"}
      ]

      Kino.DataTable.new(data)

  The tabular view allows you to quickly preview the data
  and analyze it thanks to sorting capabilities.

      data = Process.list() |> Enum.map(&Process.info/1)

      Kino.DataTable.new(
        data,
        keys: [:registered_name, :initial_call, :reductions, :stack_size]
      )
  """

  @behaviour Kino.Table

  @type t :: Kino.JS.Live.t()

  @doc """
  Creates a new kino displaying given tabular data.

  ## Options

    * `:keys` - a list of keys to include in the table for each record.
      The order is reflected in the rendered table. Optional

    * `:name` - The displayed name of the table. Defaults to `"Data"`

    * `:sorting_enabled` - whether the table should support sorting the
      data. Sorting requires traversal of the whole enumerable, so it
      may not be desirable for large lazy enumerables. Defaults to `true`

  """
  @spec new(Table.Reader.t(), keyword()) :: t()
  def new(tabular, opts \\ []) do
    tabular = normalize_tabular(tabular)

    name = Keyword.get(opts, :name, "Data")
    sorting_enabled = Keyword.get(opts, :sorting_enabled, true)
    keys = opts[:keys]

    {_, meta, _} = reader = init_reader!(tabular)

    count = meta[:count] || infer_count(reader, tabular)

    {data_rows, data_columns} =
      if keys do
        rows = Table.to_rows(reader, only: keys)
        nonexistent = keys -- meta.columns
        {rows, keys -- nonexistent}
      else
        rows = Table.to_rows(reader)
        {rows, meta.columns}
      end

    Kino.Table.new(__MODULE__, {data_rows, data_columns, count, name, sorting_enabled})
  end

  defp normalize_tabular([%struct{} | _] = tabular) do
    Enum.map(tabular, fn
      %^struct{} = item ->
        Map.reject(item, fn {key, _val} ->
          key |> Atom.to_string() |> String.starts_with?("_")
        end)

      other ->
        raise ArgumentError,
              "expected a list of %#{inspect(struct)}{} structs, but got: #{inspect(other)}"
    end)
  end

  defp normalize_tabular(tabular), do: tabular

  defp init_reader!(tabular) do
    with :none <- Table.Reader.init(tabular) do
      raise ArgumentError, "expected valid tabular data, but got: #{inspect(tabular)}"
    end
  end

  defp infer_count({_, %{count: count}, _}, _), do: count

  # Handle lists as common cases for rows
  defp infer_count({:rows, _, _}, tabular) when is_list(tabular), do: length(tabular)
  defp infer_count({:rows, _, enum}, _) when is_list(enum), do: length(enum)

  # Handle kw/maps as common cases for columns
  defp infer_count({:columns, _, _}, [{_, series} | _]) when is_list(series), do: length(series)

  defp infer_count({:columns, _, _}, %{} = tabular) when not is_map_key(tabular, :__struct__) do
    case Enum.at(tabular, 0) do
      {_, series} when is_list(series) -> length(series)
      _ -> nil
    end
  end

  # Otherwise fallback to enumerable operations
  defp infer_count({:rows, _, enum}, _) do
    case Enumerable.count(enum) do
      {:ok, count} -> count
      _ -> nil
    end
  end

  defp infer_count({:columns, _, enum}, _) do
    with {:ok, series} <- Enum.fetch(enum, 0),
         {:ok, count} <- Enumerable.count(series),
         do: count,
         else: (_ -> nil)
  end

  @impl true
  def init({data_rows, data_columns, count, name, sorting_enabled}) do
    features = Kino.Utils.truthy_keys(pagination: true, sorting: sorting_enabled)
    info = %{name: name, features: features}

    {count, slicing_fun, slicing_cache} = init_slicing(data_rows, count)

    {:ok, info,
     %{
       data_rows: data_rows,
       total_rows: count,
       slicing_fun: slicing_fun,
       slicing_cache: slicing_cache,
       columns: Enum.map(data_columns, fn key -> %{key: key, label: inspect(key)} end)
     }}
  end

  defp init_slicing(data_rows, count) do
    {count, slicing_fun} =
      case Enumerable.slice(data_rows) do
        {:ok, count, fun} when is_function(fun, 2) -> {count, fun}
        {:ok, count, fun} when is_function(fun, 3) -> {count, &fun.(&1, &2, 1)}
        _ -> {count, nil}
      end

    if slicing_fun do
      slicing_fun = fn start, length, cache ->
        max_length = max(count - start, 0)
        length = min(length, max_length)
        {slicing_fun.(start, length), count, cache}
      end

      {count, slicing_fun, nil}
    else
      cache = %{items: [], length: 0, continuation: take_init(data_rows)}

      slicing_fun = fn start, length, cache ->
        to_take = start + length - cache.length

        cache =
          if to_take > 0 and cache.continuation != nil do
            {items, length, continuation} = take(cache.continuation, to_take)

            %{
              cache
              | items: cache.items ++ items,
                length: cache.length + length,
                continuation: continuation
            }
          else
            cache
          end

        count = if(cache.continuation, do: count, else: cache.length)

        {Enum.slice(cache.items, start, length), count, cache}
      end

      {count, slicing_fun, cache}
    end
  end

  defp take_init(enumerable) do
    reducer = fn
      x, {acc, 1} ->
        {:suspend, {[x | acc], 0}}

      x, {acc, n} when n > 1 ->
        {:cont, {[x | acc], n - 1}}
    end

    &Enumerable.reduce(enumerable, &1, reducer)
  end

  defp take(continuation, amount) do
    case continuation.({:cont, {[], amount}}) do
      {:suspended, {items, 0}, continuation} ->
        {Enum.reverse(items), amount, continuation}

      {:done, {items, left}} ->
        {Enum.reverse(items), amount - left, nil}
    end
  end

  @impl true
  def get_data(rows_spec, state) do
    {records, count, slicing_cache} =
      query(state.data_rows, state.slicing_fun, state.slicing_cache, rows_spec)

    rows =
      Enum.map(records, fn record ->
        %{fields: Map.new(record, fn {key, value} -> {key, inspect(value)} end)}
      end)

    total_rows = count || state.total_rows

    {:ok,
     %{
       columns: state.columns,
       rows: rows,
       total_rows: total_rows
     }, %{state | total_rows: total_rows, slicing_cache: slicing_cache}}
  end

  defp query(data, slicing_fun, slicing_cache, rows_spec) do
    if order_by = rows_spec[:order_by] do
      sorted = Enum.sort_by(data, & &1[order_by], rows_spec.order)
      records = Enum.slice(sorted, rows_spec.offset, rows_spec.limit)
      {records, Enum.count(sorted), slicing_cache}
    else
      slicing_fun.(rows_spec.offset, rows_spec.limit, slicing_cache)
    end
  end
end
