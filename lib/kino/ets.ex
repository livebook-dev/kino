defmodule Kino.ETS do
  @moduledoc """
  A kino for interactively viewing an ETS table.

  ## Examples

      tid = :ets.new(:users, [:set, :public])
      Kino.ETS.new(tid)

      Kino.ETS.new(:elixir_config)
  """

  @behaviour Kino.Table

  @type t :: Kino.JS.Live.t()

  @doc """
  Creates a new kino displaying the given ETS table.

  Note that private tables cannot be read by an arbitrary process,
  so the given table must have either public or protected access.
  """
  @spec new(:ets.tid()) :: t()
  def new(tid) do
    case :ets.info(tid, :protection) do
      :private ->
        raise ArgumentError,
              "the given table must be either public or protected, but a private one was given"

      :undefined ->
        raise ArgumentError,
              "the given table identifier #{inspect(tid)} does not refer to an existing ETS table"

      _ ->
        :ok
    end

    Kino.Table.new(__MODULE__, {tid})
  end

  @impl true
  def init({tid}) do
    table_name = :ets.info(tid, :name)
    name = "ETS #{inspect(table_name)}"
    info = %{name: name, features: [:refetch, :pagination]}
    {:ok, info, %{tid: tid}}
  end

  @impl true
  def get_data(rows_spec, state) do
    records = get_records(state.tid, rows_spec)
    rows = Enum.map(records, fn record -> %{fields: %{0 => inspect(record)}} end)
    total_rows = :ets.info(state.tid, :size)
    columns = [%{key: 0, label: "row", type: "tuple"}]
    {:ok, %{columns: columns, rows: rows, total_rows: total_rows}, state}
  end

  defp get_records(tid, rows_spec) do
    query = :ets.table(tid)
    cursor = :qlc.cursor(query)

    if rows_spec.offset > 0 do
      :qlc.next_answers(cursor, rows_spec.offset)
    end

    records = :qlc.next_answers(cursor, rows_spec.limit)
    :qlc.delete_cursor(cursor)
    records
  end
end
