defmodule Kino.DataTable do
  @moduledoc """
  A widget for interactively viewing enumerable data.

  The data must be an enumerable of records, where each
  record is either map, struct or keyword list.

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

  alias Kino.Utils

  @type t :: Kino.JS.Live.t()

  @doc """
  Starts a widget process with enumerable tabular data.

  ## Options

    * `:keys` - a list of keys to include in the table for each record.
      The order is reflected in the rendered table. Optional.

    * `:name` - The displayed name of the table. Defaults to `"Data"`.

    * `:sorting_enabled` - whether the widget should support sorting the data.
      Sorting requires traversal of the whole enumerable, so it may not be
      desirable for lazy enumerables. Defaults to `true` if data is a list
      and `false` otherwise.

    * `:show_underscored` - whether to include record keys starting with underscore.
      This option is ignored if `:keys` is also given. Defaults to `false`.
  """
  @spec new(Enum.t(), keyword()) :: t()
  def new(data, opts \\ []) do
    validate_data!(data)

    keys = opts[:keys]
    name = Keyword.get(opts, :name, "Data")
    sorting_enabled = Keyword.get(opts, :sorting_enabled, is_list(data))
    show_underscored = Keyword.get(opts, :show_underscored, false)

    opts = %{
      data: data,
      keys: keys,
      name: name,
      sorting_enabled: sorting_enabled,
      show_underscored: show_underscored
    }

    Kino.Table.new(__MODULE__, opts)
  end

  # Validate data only if we have a whole list upfront
  defp validate_data!(data) when is_list(data) do
    Enum.reduce(data, nil, fn record, type ->
      case record_type(record) do
        :other ->
          raise ArgumentError,
                "expected record to be either map, struct or keyword list, got: #{inspect(record)}"

        first_type when type == nil ->
          first_type

        ^type ->
          type

        other_type ->
          raise ArgumentError,
                "expected records to have the same data type, found #{type} and #{other_type}"
      end
    end)
  end

  defp validate_data!(_data), do: :ok

  defp record_type(record) do
    cond do
      is_struct(record) -> :struct
      is_map(record) -> :map
      Keyword.keyword?(record) -> :keyword_list
      true -> :other
    end
  end

  @impl true
  def init(opts) do
    %{
      data: data,
      keys: keys,
      name: name,
      sorting_enabled: sorting_enabled,
      show_underscored: show_underscored
    } = opts

    features = Kino.Utils.truthy_keys(pagination: true, sorting: sorting_enabled)
    info = %{name: name, features: features}
    total_rows = Enum.count(data)

    {:ok, info,
     %{
       data: data,
       total_rows: total_rows,
       columns: keys && Utils.Table.keys_to_columns(keys),
       show_underscored: show_underscored
     }}
  end

  @impl true
  def get_data(rows_spec, state) do
    records = get_records(state.data, rows_spec)

    columns =
      if columns = state.columns do
        columns
      else
        columns = Utils.Table.columns_for_records(records)

        if state.show_underscored do
          columns
        else
          Enum.reject(columns, &underscored?(&1.key))
        end
      end

    rows = Utils.Table.records_to_rows(records, columns)

    {:ok, %{columns: columns, rows: rows, total_rows: state.total_rows}, state}
  end

  defp get_records(data, rows_spec) do
    sorted_data =
      if order_by = rows_spec[:order_by] do
        Enum.sort_by(data, &Utils.Table.get_field(&1, order_by), rows_spec.order)
      else
        data
      end

    Enum.slice(sorted_data, rows_spec.offset, rows_spec.limit)
  end

  defp underscored?(key) when is_atom(key) do
    key |> Atom.to_string() |> String.starts_with?("_")
  end

  defp underscored?(_key), do: false
end
