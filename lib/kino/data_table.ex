defmodule Kino.DataTable do
  @moduledoc """
  A widget for interactively viewing enumerable data.

  The data must be an enumerable of records, where each
  record is either map, struct, keyword list or tuple.

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

  @doc false
  use GenServer, restart: :temporary

  alias Kino.Utils.Table

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

    * `:show_underscored` - whether to include record keys starting with underscore.
      This option is ignored if `:keys` is also given. Defaults to `false`.
  """
  @spec new(Enum.t(), keyword()) :: t()
  def new(data, opts \\ []) do
    validate_data!(data)

    parent = self()
    keys = opts[:keys]
    sorting_enabled = Keyword.get(opts, :sorting_enabled, is_list(data))
    show_underscored = Keyword.get(opts, :show_underscored, false)

    opts = [
      data: data,
      parent: parent,
      keys: keys,
      sorting_enabled: sorting_enabled,
      show_underscored: show_underscored
    ]

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
        :other ->
          raise ArgumentError,
                "expected record to be either map, struct, tuple or keyword list, got: #{inspect(record)}"

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
    show_underscored = Keyword.fetch!(opts, :show_underscored)

    parent_monitor_ref = Process.monitor(parent)

    total_rows = Enum.count(data)

    {:ok,
     %{
       parent_monitor_ref: parent_monitor_ref,
       data: data,
       total_rows: total_rows,
       keys: keys,
       sorting_enabled: sorting_enabled,
       show_underscored: show_underscored
     }}
  end

  @impl true
  def handle_info({:connect, pid}, state) do
    columns =
      if state.keys do
        Table.keys_to_columns(state.keys)
      else
        []
      end

    features = Kino.Utils.truthy_keys(pagination: true, sorting: state.sorting_enabled)

    send(pid, {:connect_reply, %{name: "Data", columns: columns, features: features}})

    {:noreply, state}
  end

  def handle_info({:get_rows, pid, rows_spec}, state) do
    records = get_records(state.data, rows_spec)

    {columns, keys} =
      if state.keys do
        {:initial, state.keys}
      else
        columns = Table.columns_for_records(records)

        columns =
          if state.show_underscored,
            do: columns,
            else: Enum.reject(columns, &underscored?(&1.key))

        keys = Enum.map(columns, & &1.key)
        {columns, keys}
      end

    rows = Enum.map(records, &Table.record_to_row(&1, keys))

    send(pid, {:rows, %{rows: rows, total_rows: state.total_rows, columns: columns}})

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _object, _reason}, %{parent_monitor_ref: ref} = state) do
    {:stop, :shutdown, state}
  end

  defp get_records(data, rows_spec) do
    sorted_data =
      if order_by = rows_spec[:order_by] do
        Enum.sort_by(data, &Table.get_field(&1, order_by), rows_spec.order)
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
