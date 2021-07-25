defmodule Kino.Ecto do
  @moduledoc """
  A widget for interactively viewing `Ecto` query results.

  The data must be an enumerable of records, where each
  record is either map, struct, keyword list or tuple.

  ## Examples

  The widget primarly allows for viewing a database table
  given a schema:

      Kino.Ecto.new(Weather, Repo)

  However, the first argument can be any queryable, so
  you can pipe arbitrary queries directly to the widget:

      from(w in Weather, where: w.city == "New York")
      |> Kino.Ecto.new(Repo)
  """

  use GenServer, restart: :temporary

  alias Kino.Utils.Table

  defstruct [:pid]

  @type t :: %__MODULE__{pid: pid()}

  @typedoc false
  @type state :: %{
          parent_monitor_ref: reference(),
          repo: Ecto.Repo.t(),
          queryable: Ecto.Queryable.t()
        }

  @doc """
  Starts a widget process with the given queryable as
  the data source.
  """
  @spec new(Ecto.Queryable.t(), Ecto.Repo.t()) :: t()
  def new(queryable, repo) when is_atom(repo) do
    unless queryable?(queryable) do
      raise ArgumentError,
            "expected a term implementing the Ecto.Queryable protocol, got: #{inspect(queryable)}"
    end

    parent = self()
    opts = [repo: repo, queryable: queryable, parent: parent]

    {:ok, pid} = DynamicSupervisor.start_child(Kino.WidgetSupervisor, {__MODULE__, opts})

    %__MODULE__{pid: pid}
  end

  defp queryable?(term) do
    Ecto.Queryable.impl_for(term) != nil
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    queryable = Keyword.fetch!(opts, :queryable)
    parent = Keyword.fetch!(opts, :parent)

    parent_monitor_ref = Process.monitor(parent)

    {:ok, %{parent_monitor_ref: parent_monitor_ref, repo: repo, queryable: queryable}}
  end

  @impl true
  def handle_info({:connect, pid}, state) do
    name = state.queryable |> query_source() |> to_string()
    columns = state.queryable |> keys_from_queryable() |> Table.keys_to_columns()

    features =
      Kino.Utils.truthy_keys(
        refetch: true,
        pagination: true,
        # If the user specifies custom select, the record keys
        # are not valid "order by" fields, so we disable sorting
        sorting: default_select_query?(state.queryable)
      )

    send(
      pid,
      {:connect_reply, %{name: name, columns: columns, features: features}}
    )

    {:noreply, state}
  end

  def handle_info({:get_rows, pid, rows_spec}, state) do
    {total_rows, records} = get_records(state.repo, state.queryable, rows_spec)

    {columns, keys} =
      case keys_from_queryable(state.queryable) do
        [] ->
          columns = Table.columns_for_records(records)
          keys = Enum.map(columns, & &1.key)
          {columns, keys}

        keys ->
          {:initial, keys}
      end

    rows = Enum.map(records, &Table.record_to_row(&1, keys))

    send(pid, {:rows, %{rows: rows, total_rows: total_rows, columns: columns}})

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _object, _reason}, %{parent_monitor_ref: ref} = state) do
    {:stop, :shutdown, state}
  end

  defp get_records(repo, queryable, rows_spec) do
    count = repo.aggregate(queryable, :count)
    query = prepare_query(queryable, rows_spec)
    records = repo.all(query)
    {count, records}
  end

  defp query_source(queryable) do
    %{from: %{source: {source, _schema}}} = Ecto.Queryable.to_query(queryable)
    source
  end

  defp default_select_query?(queryable) do
    query = Ecto.Queryable.to_query(queryable)
    query.select == nil
  end

  defp keys_from_queryable(queryable) do
    schema = Table.ecto_schema(queryable)

    if schema != nil and default_select_query?(queryable) do
      schema.__schema__(:fields)
    else
      []
    end
  end

  if Code.ensure_loaded?(Ecto.Query) do
    defp prepare_query(queryable, rows_spec) do
      import Ecto.Query, only: [from: 2]
      query = from(q in queryable, limit: ^rows_spec.limit, offset: ^rows_spec.offset)

      if rows_spec[:order_by] do
        query = Ecto.Query.exclude(query, :order_by)
        order_by = [{rows_spec.order, rows_spec.order_by}]
        from(q in query, order_by: ^order_by)
      else
        query
      end
    end
  else
    defp prepare_query(_queryable, _rows_spec), do: raise "Ecto is missing"
  end
end
