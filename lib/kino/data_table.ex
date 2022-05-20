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

    {data_rows, data_columns} =
      if keys = opts[:keys] do
        {rows, %{columns: columns}} = Table.to_rows_with_info(tabular, only: keys)
        nonexistent = keys -- columns
        {rows, keys -- nonexistent}
      else
        {rows, %{columns: columns}} = Table.to_rows_with_info(tabular)
        {rows, columns}
      end

    Kino.Table.new(__MODULE__, {data_rows, data_columns, name, sorting_enabled})
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

  @impl true
  def init({data_rows, data_columns, name, sorting_enabled}) do
    features = Kino.Utils.truthy_keys(pagination: true, sorting: sorting_enabled)
    info = %{name: name, features: features}
    total_rows = Enum.count(data_rows)

    {:ok, info,
     %{
       data_rows: data_rows,
       total_rows: total_rows,
       columns: Enum.map(data_columns, fn key -> %{key: key, label: inspect(key)} end)
     }}
  end

  @impl true
  def get_data(rows_spec, state) do
    records = query(state.data_rows, rows_spec)

    rows =
      Enum.map(records, fn record ->
        %{fields: Map.new(record, fn {key, value} -> {key, inspect(value)} end)}
      end)

    {:ok, %{columns: state.columns, rows: rows, total_rows: state.total_rows}, state}
  end

  defp query(data, rows_spec) do
    sorted_data =
      if order_by = rows_spec[:order_by] do
        Enum.sort_by(data, & &1[order_by], rows_spec.order)
      else
        data
      end

    Enum.slice(sorted_data, rows_spec.offset, rows_spec.limit)
  end
end
