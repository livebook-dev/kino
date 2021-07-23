defmodule Kino.Utils.Table do
  @moduledoc false

  # Common functions for handling various Elixir
  # terms as table records.

  @doc """
  Computes table columns that accomodate for all the given records.
  """
  def columns_for_records(records) do
    case Enum.at(records, 0) do
      nil ->
        []

      first_record ->
        first_record_columns = columns_for_record(first_record)

        all_columns =
          records
          |> Enum.reduce(MapSet.new(), fn record, columns ->
            record
            |> columns_for_record()
            |> MapSet.new()
            |> MapSet.union(columns)
          end)
          |> MapSet.to_list()
          |> Enum.sort_by(& &1.key)

        # If all records have the same structure, keep the order,
        # otherwise return the sorted accumulated columns
        if length(first_record_columns) == length(all_columns) do
          first_record_columns
        else
          all_columns
        end
    end
  end

  defp columns_for_record(record) when is_tuple(record) do
    record
    |> Tuple.to_list()
    |> Enum.with_index()
    |> Enum.map(&elem(&1, 1))
    |> keys_to_columns()
  end

  defp columns_for_record(record) when is_map(record) do
    if schema = ecto_schema(record) do
      schema.__schema__(:fields)
    else
      record |> Map.keys() |> Enum.sort()
    end
    |> keys_to_columns()
  end

  defp columns_for_record(record) when is_list(record) do
    record
    |> Keyword.keys()
    |> keys_to_columns()
  end

  defp columns_for_record(_record) do
    # If the record is neither of the expected enumerables,
    # we treat it as a single column value
    keys_to_columns([:item])
  end

  @doc """
  Converts keys to column specifications.
  """
  def keys_to_columns(keys) do
    Enum.map(keys, fn key -> %{key: key, label: inspect(key)} end)
  end

  @doc """
  Looks up record field value by key.
  """
  def get_field(record, key)

  def get_field(record, key) when is_tuple(record) do
    if key < tuple_size(record) do
      elem(record, key)
    else
      nil
    end
  end

  def get_field(record, key) when is_list(record) do
    record[key]
  end

  def get_field(record, key) when is_map(record) do
    Map.get(record, key)
  end

  def get_field(record, :item) do
    record
  end

  @doc """
  Converts a record to row specification given a list
  of desired keys.
  """
  def record_to_row(record, keys) do
    fields =
      Map.new(keys, fn key ->
        value = get_field(record, key)
        {key, inspect(value)}
      end)

    # Note: id is opaque to the client, and we don't need it for now
    %{id: nil, fields: fields}
  end

  @doc """
  Extracts schema module from the given struct or queryable.

  If no schema found, `nil` is returned.
  """
  def ecto_schema(queryable)

  def ecto_schema(%{from: %{source: {_source, schema}}}) do
    schema
  end

  def ecto_schema(queryable) when is_atom(queryable) do
    if Code.ensure_loaded?(queryable) and function_exported?(queryable, :__schema__, 1) do
      queryable
    else
      nil
    end
  end

  def ecto_schema(struct) when is_struct(struct) do
    ecto_schema(struct.__struct__)
  end

  def ecto_schema(_queryable), do: nil
end
