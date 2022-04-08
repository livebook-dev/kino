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

    {:ok, info, %{repo: repo, queryable: queryable, columns: columns_for_queryable(queryable)}}
  end

  @impl true
  def get_data(rows_spec, state) do
    {total_rows, records} = get_records(state.repo, state.queryable, rows_spec)

    columns = with [] <- state.columns, do: columns_for_records(records)
    rows = records_to_rows(records, columns)

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
    schema = ecto_schema(queryable)

    if schema != nil and default_select_query?(queryable) do
      columns_for_schema(schema)
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

  defp columns_for_records(records) do
    case Enum.at(records, 0) do
      nil -> []
      first_record -> columns_for_record(first_record)
    end
  end

  defp columns_for_record(record) when is_tuple(record) do
    size = tuple_size(record)
    keys_to_columns(0..(size - 1))
  end

  defp columns_for_record(record) when is_map(record) do
    if schema = ecto_schema(record) do
      columns_for_schema(schema)
    else
      record |> Map.keys() |> Enum.sort() |> keys_to_columns()
    end
  end

  defp columns_for_record(record) when is_list(record) do
    size = length(record)
    keys_to_columns(0..(size - 1))
  end

  defp columns_for_record(_record) do
    # If the record is neither of the expected enumerables,
    # we treat it as a single column value
    keys_to_columns([:item])
  end

  defp keys_to_columns(keys) do
    Enum.map(keys, fn key -> %{key: key, label: inspect(key)} end)
  end

  defp columns_for_schema(schema) do
    for field <- schema.__schema__(:fields) do
      type = schema.__schema__(:type, field)
      %{key: field, label: inspect(field), type: ecto_type_to_string(type)}
    end
  end

  defp ecto_type_to_string({:parameterized, module, _info}), do: inspect(module)
  defp ecto_type_to_string(type), do: inspect(type)

  defp records_to_rows(records, columns) do
    for record <- records do
      fields =
        Map.new(columns, fn column ->
          value = get_field(record, column.key)
          {column.key, inspect(value)}
        end)

      %{fields: fields}
    end
  end

  defp get_field(record, key) when is_tuple(record), do: elem(record, key)
  defp get_field(record, key) when is_list(record), do: Enum.at(record, key)
  defp get_field(record, key) when is_map(record), do: Map.get(record, key)
  defp get_field(record, :item), do: record

  defp ecto_schema(queryable)

  defp ecto_schema(%{from: %{source: {_source, schema}}}), do: schema

  defp ecto_schema(queryable) when is_atom(queryable) do
    if Code.ensure_loaded?(queryable) and function_exported?(queryable, :__schema__, 1) do
      queryable
    else
      nil
    end
  end

  defp ecto_schema(%struct{}), do: ecto_schema(struct)
  defp ecto_schema(_queryable), do: nil
end
