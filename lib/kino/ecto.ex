defmodule Kino.Ecto do
  @moduledoc """
  A widget for interactively viewing `Ecto` query results.

  The data must be an enumerable of records, where each
  record is either map, struct, keyword list or tuple.

  ## Examples

  The widget primarily allows for viewing a database table
  given a schema:

      Kino.Ecto.new(Weather, Repo)

  However, the first argument can be any queryable, so
  you can pipe arbitrary queries directly to the widget:

      from(w in Weather, where: w.city == "New York")
      |> Kino.Ecto.new(Repo)
  """

  @behaviour Kino.Table

  alias Kino.Utils

  @type t :: Kino.JS.Live.t()

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

    Kino.Table.new(__MODULE__, {repo, queryable})
  end

  defp queryable?(term) do
    Ecto.Queryable.impl_for(term) != nil
  end

  @impl true
  def init({repo, queryable}) do
    name = queryable |> query_source() |> to_string()

    features =
      Kino.Utils.truthy_keys(
        refetch: true,
        pagination: true,
        # If the user specifies custom select, the record keys
        # are not valid "order by" fields, so we disable sorting
        sorting: default_select_query?(queryable)
      )

    info = %{name: name, features: features}

    {:ok, info, %{repo: repo, queryable: queryable}}
  end

  @impl true
  def get_data(rows_spec, state) do
    {total_rows, records} = get_records(state.repo, state.queryable, rows_spec)

    columns =
      case columns_for_queryable(state.queryable) do
        [] -> Utils.Table.columns_for_records(records)
        columns -> columns
      end

    rows = Utils.Table.records_to_rows(records, columns)

    {:ok, %{columns: columns, rows: rows, total_rows: total_rows}, state}
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

  defp columns_for_queryable(queryable) do
    schema = Utils.Table.ecto_schema(queryable)

    if schema != nil and default_select_query?(queryable) do
      Utils.Table.columns_for_schema(schema)
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
    defp prepare_query(_queryable, _rows_spec), do: raise("Ecto is missing")
  end
end
