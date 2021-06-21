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

      Kino.DataTable.start(data)

  The tabular view allows you to quickly preview the data
  and analyze it thanks to sorting capabilities.

      data = Process.list() |> Enum.map(&Process.info/1)

      Kino.DataTable.start(
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
  """
  @spec start(Enum.t(), keyword()) :: t()
  def start(data, opts \\ []) do
    validate_data!(data)

    parent = self()
    keys = opts[:keys]
    opts = [data: data, parent: parent, keys: keys]

    {:ok, pid} = DynamicSupervisor.start_child(Kino.WidgetSupervisor, {__MODULE__, opts})

    %__MODULE__{pid: pid}
  end

  defp validate_data!(data) do
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

    parent_monitor_ref = Process.monitor(parent)

    columns =
      if keys do
        Enum.map(keys, &key_to_column/1)
      else
        columns_structure(data)
      end

    total_rows = Enum.count(data)

    {:ok,
     %{
       parent_monitor_ref: parent_monitor_ref,
       data: data,
       total_rows: total_rows,
       columns: columns
     }}
  end

  @impl true
  def handle_info({:connect, pid}, state) do
    send(
      pid,
      {:connect_reply, %{name: "Data", columns: state.columns, features: [:pagination, :sorting]}}
    )

    {:noreply, state}
  end

  def handle_info({:get_rows, pid, rows_spec}, state) do
    records = get_records(state.data, rows_spec)
    keys = Enum.map(state.columns, & &1.key)
    rows = Enum.map(records, &record_to_row(&1, keys))

    send(pid, {:rows, %{rows: rows, total_rows: state.total_rows, columns: :initial}})

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _object, _reason}, %{parent_monitor_ref: ref} = state) do
    {:stop, :shutdown, state}
  end

  defp columns_structure([]), do: []

  defp columns_structure([record | _] = records) do
    first_record_columns = columns_structure_for_record(record)

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
    elem(record, key)
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
