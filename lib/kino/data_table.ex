defmodule Kino.DataTable do
  @moduledoc """
  A kino for interactively viewing tabular data.

  ## Examples

      data = [
        %{id: 1, name: "Elixir", website: "https://elixir-lang.org"},
        %{id: 2, name: "Erlang", website: "https://www.erlang.org"}
      ]

      Kino.DataTable.new(data)

  The tabular view allows you to quickly preview the data
  and analyze it thanks to sorting capabilities.

      data =
        for pid <- Process.list() do
          pid |> Process.info() |> Keyword.merge(registered_name: nil)
        end

      Kino.DataTable.new(
        data,
        keys: [:registered_name, :initial_call, :reductions, :stack_size]
      )
  """

  @behaviour Kino.Table

  @type t :: Kino.Table.t()

  @doc """
  Creates a new kino displaying given tabular data.

  ## Options

    * `:keys` - a list of keys to include in the table for each record.
      The order is reflected in the rendered table. Optional

    * `:name` - The displayed name of the table. Defaults to `"Data"`

    * `:sorting_enabled` - whether the table should support sorting the
      data. Sorting requires traversal of the whole enumerable, so it
      may not be desirable for large lazy enumerables. Defaults to `true`

   * `:formatter` - a 2-arity function that is used to format the data
     in the table. The first parameter passed is the `key` (column name) and
     the second is the value to be formatted. When formatting column headings
     the key is the special value `:__header__`. The formatter function must
     return either `{:ok, string}` or `:default`. When the return value is
     `:default` the default data table formatting is applied.

    * `:num_rows` - the number of rows to show in the table. Defaults to `10`.

  """
  @spec new(Table.Reader.t(), keyword()) :: t()
  def new(tabular, opts \\ []) do
    name = Keyword.get(opts, :name, "Data")
    sorting_enabled = Keyword.get(opts, :sorting_enabled, true)
    formatter = Keyword.get(opts, :formatter)
    num_rows = Keyword.get(opts, :num_rows)
    {data_rows, data_columns, count, inspected} = prepare_data(tabular, opts)

    Kino.Table.new(
      __MODULE__,
      {data_rows, data_columns, count, name, sorting_enabled, inspected, formatter, num_rows},
      export: fn state -> {"text", state.inspected} end
    )
  end

  @doc """
  Updates the table to display a new tabular data.

  ## Options

    * `:keys` - a list of keys to include in the table for each record.
      The order is reflected in the rendered table. Optional

  ## Examples

      data = [
        %{id: 1, name: "Elixir", website: "https://elixir-lang.org"},
        %{id: 2, name: "Erlang", website: "https://www.erlang.org"}
      ]

      kino = Kino.DataTable.new(data)

  Once created, you can update the table to display new data:

      new_data = [
        %{id: 1, name: "Elixir Lang", website: "https://elixir-lang.org"},
        %{id: 2, name: "Erlang Lang", website: "https://www.erlang.org"}
      ]

      Kino.DataTable.update(kino, new_data)
  """
  def update(kino, tabular, opts \\ []) do
    {data_rows, data_columns, count, inspected} = prepare_data(tabular, opts)
    Kino.Table.update(kino, {data_rows, data_columns, count, inspected})
  end

  defp prepare_data(tabular, opts) do
    tabular = normalize_tabular(tabular)
    keys = opts[:keys]

    {_, meta, _} = reader = init_reader!(tabular)

    count = meta[:count] || infer_count(reader, tabular)

    {data_rows, data_columns} =
      if keys do
        data = Table.to_rows(reader, only: keys)
        nonexistent = keys -- meta.columns
        {data, keys -- nonexistent}
      else
        data = Table.to_rows(reader)
        {data, meta.columns}
      end

    inspected = inspect(tabular)

    {data_rows, data_columns, count, inspected}
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
  def init(
        {data_rows, data_columns, count, name, sorting_enabled, inspected, formatter, num_rows}
      ) do
    features = Kino.Utils.truthy_keys(pagination: true, sorting: sorting_enabled)
    info = %{name: name, features: features}
    info = if(num_rows, do: Map.put(info, :num_rows, num_rows), else: info)

    {count, slicing_fun, slicing_cache} = init_slicing(data_rows, count)

    {:ok, info,
     %{
       data_rows: data_rows,
       total_rows: count,
       slicing_fun: slicing_fun,
       slicing_cache: slicing_cache,
       columns:
         Enum.map(data_columns, fn key ->
           %{key: key, label: value_to_string(:__header__, key, formatter)}
         end),
       inspected: inspected,
       formatter: formatter
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

      {:halted, {items, left}} ->
        {Enum.reverse(items), amount - left, nil}

      {:done, {items, left}} ->
        {Enum.reverse(items), amount - left, nil}
    end
  end

  @impl true
  def get_data(rows_spec, state) do
    {records, count, slicing_cache} =
      query(state.data_rows, state.slicing_fun, state.slicing_cache, rows_spec)

    data =
      Enum.map(records, fn record ->
        Enum.map(state.columns, fn column ->
          value_to_string(column.key, Map.fetch!(record, column.key), state.formatter)
        end)
      end)

    total_rows = count || state.total_rows

    {:ok,
     %{
       columns: state.columns,
       data: {:rows, data},
       total_rows: total_rows
     }, %{state | total_rows: total_rows, slicing_cache: slicing_cache}}
  end

  defp query(data, slicing_fun, slicing_cache, rows_spec) do
    if order = rows_spec[:order] do
      sorted = Enum.sort_by(data, & &1[order.key], order.direction)
      records = Enum.slice(sorted, rows_spec.offset, rows_spec.limit)
      {records, Enum.count(sorted), slicing_cache}
    else
      slicing_fun.(rows_spec.offset, rows_spec.limit, slicing_cache)
    end
  end

  defp value_to_string(_key, value, nil) do
    value_to_string(value)
  end

  defp value_to_string(key, value, formatter) do
    case formatter.(key, value) do
      {:ok, string} -> string
      :default -> value_to_string(value)
    end
  end

  defp value_to_string(value) when is_atom(value), do: inspect(value)

  defp value_to_string(value) when is_list(value) do
    if List.ascii_printable?(value) do
      List.to_string(value)
    else
      inspect(value)
    end
  end

  defp value_to_string(value) when is_binary(value) do
    inspect_opts = Inspect.Opts.new([])

    if String.printable?(value, inspect_opts.limit) do
      value
    else
      inspect(value)
    end
  end

  defp value_to_string(value) do
    if mod = String.Chars.impl_for(value) do
      apply(mod, :to_string, [value])
    else
      inspect(value)
    end
  end

  @impl true
  def on_update({data_rows, data_columns, count, inspected}, state) do
    {count, slicing_fun, slicing_cache} = init_slicing(data_rows, count)

    {:ok,
     %{
       state
       | data_rows: data_rows,
         total_rows: count,
         slicing_fun: slicing_fun,
         slicing_cache: slicing_cache,
         columns:
           Enum.map(data_columns, fn key ->
             %{key: key, label: value_to_string(:__header__, key, state.formatter)}
           end),
         inspected: inspected
     }}
  end
end
