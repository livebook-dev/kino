defmodule Kino.DataTable do
  @moduledoc """
  A widget for interactively viewing enumerable data.

  The data must be an enumerable of records, where each
  record is either map, keyword list or tuple. Structs
  however must be manually converted to maps.

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

  use GenServer, restart: :temporary

  defstruct [:pid]

  @type t :: %__MODULE__{pid: pid()}

  @typedoc false
  @type state :: %{
          parent_monitor_ref: reference(),
          data: Enum.t(),
          total_rows: non_neg_integer()
        }

  @doc """
  Starts a widget process with enumerable tabular data.

  ## Options

    * `:keys` - a list of keys to include in the table for each record.
      The order is reflected in the rendered table. For tuples use 0-based
      indices. Optional.

    * `:sorting_enabled` - whether the widget should support sorting the data.
      Sorting requires traversal of the whole enumerable, so it may not be
      desirable for lazy enumerables. Defaults to `true` if data is a list
      and `false` otherwise.
  """
  @spec new(Enum.t(), keyword()) :: t()
  def new(data, opts \\ []) do
    validate_data!(data)

    parent = self()
    keys = opts[:keys]
    sorting_enabled = Keyword.get(opts, :sorting_enabled, is_list(data))
    opts = [data: data, parent: parent, keys: keys, sorting_enabled: sorting_enabled]

    {:ok, pid} = DynamicSupervisor.start_child(Kino.WidgetSupervisor, {__MODULE__, opts})

    %__MODULE__{pid: pid}
  end

  # TODO: remove in v0.3.0
  @deprecated "Use Kino.DataTable.new/2 instead"
  def start(data, opts \\ []), do: new(data, opts)

  # Validate data only if we have a whole list upfront
  defp validate_data!(data) when is_list(data) do
    Enum.reduce(data, nil, fn record, type ->
      case record_type(record) do
        :struct ->
          raise ArgumentError,
                "struct records are not supported, you need to convert them to maps explicitly"

        :other ->
          raise ArgumentError,
                "expected record to be either map, tuple or keyword list, got: #{inspect(record)}"

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
      is_tuple(record) -> :tuple
      Keyword.keyword?(record) -> :keyword_list
      true -> :other
    end
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    data = Keyword.fetch!(opts, :data)
    parent = Keyword.fetch!(opts, :parent)
    keys = Keyword.fetch!(opts, :keys)
    sorting_enabled = Keyword.fetch!(opts, :sorting_enabled)

    parent_monitor_ref = Process.monitor(parent)

    total_rows = Enum.count(data)

    {:ok,
     %{
       parent_monitor_ref: parent_monitor_ref,
       data: data,
       total_rows: total_rows,
       keys: keys,
       sorting_enabled: sorting_enabled
     }}
  end

  @impl true
  def handle_info({:connect, pid}, state) do
    columns =
      if state.keys do
        Enum.map(state.keys, &key_to_column/1)
      else
        []
      end

    features =
      [pagination: true, sorting: state.sorting_enabled]
      |> Enum.filter(&elem(&1, 1))
      |> Keyword.keys()

    send(pid, {:connect_reply, %{name: "Data", columns: columns, features: features}})

    {:noreply, state}
  end

  def handle_info({:get_rows, pid, rows_spec}, state) do
    records = get_records(state.data, rows_spec)

    {columns, keys} =
      if state.keys do
        {:initial, state.keys}
      else
        columns = columns_structure(records)
        keys = Enum.map(columns, & &1.key)
        {columns, keys}
      end

    rows = Enum.map(records, &record_to_row(&1, keys))

    send(pid, {:rows, %{rows: rows, total_rows: state.total_rows, columns: columns}})

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _object, _reason}, %{parent_monitor_ref: ref} = state) do
    {:stop, :shutdown, state}
  end

  defp columns_structure(records) do
    case Enum.at(records, 0) do
      nil ->
        []

      first_record ->
        first_record_columns = columns_structure_for_record(first_record)

        all_columns =
          records
          |> Enum.reduce(MapSet.new(), fn record, columns ->
            record
            |> columns_structure_for_record()
            |> MapSet.new()
            |> MapSet.union(columns)
          end)
          |> MapSet.to_list()
          |> Enum.sort_by(& &1.key)

        # If all records have the same structure, keep the order,
        # otherwise sort the accumulated columns
        if length(first_record_columns) == length(all_columns) do
          first_record_columns
        else
          all_columns
        end
    end
  end

  defp columns_structure_for_record(record) when is_tuple(record) do
    record
    |> Tuple.to_list()
    |> Enum.with_index()
    |> Enum.map(fn {_, idx} -> key_to_column(idx) end)
  end

  defp columns_structure_for_record(record) when is_map(record) do
    record
    |> Map.keys()
    |> Enum.sort()
    |> Enum.map(&key_to_column/1)
  end

  defp columns_structure_for_record(record) when is_list(record) do
    record
    |> Keyword.keys()
    |> Enum.map(&key_to_column/1)
  end

  defp key_to_column(key), do: %{key: key, label: inspect(key)}

  defp get_records(data, rows_spec) do
    sorted_data =
      if order_by = rows_spec[:order_by] do
        Enum.sort_by(data, fn record -> get_field(record, order_by) end, rows_spec.order)
      else
        data
      end

    Enum.slice(sorted_data, rows_spec.offset, rows_spec.limit)
  end

  defp get_field(record, key) when is_tuple(record) do
    if key < tuple_size(record) do
      elem(record, key)
    else
      nil
    end
  end

  defp get_field(record, key) when is_map(record) or is_list(record) do
    record[key]
  end

  defp record_to_row(record, keys) do
    fields =
      Map.new(keys, fn key ->
        value = get_field(record, key)
        {key, inspect(value)}
      end)

    # Note: id is opaque to the client, and we don't need it for now
    %{id: nil, fields: fields}
  end
end
