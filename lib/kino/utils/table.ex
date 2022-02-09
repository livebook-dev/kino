defmodule Kino.Utils.Table do
  @moduledoc false

  # Common functions for handling various Elixir terms
  # as table records.

  @type record :: map() | list({term(), term()}) | tuple() | term()

  @doc """
  Computes table column specifications that accommodate
  the given records.

  Note that the columns are computed based on the first
  record, if present.
  """
  @spec columns_for_records(list(record())) :: list(Kino.Table.column())
  def columns_for_records(records) do
    case Enum.at(records, 0) do
      nil -> []
      first_record -> columns_for_record(first_record)
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
      columns_for_schema(schema)
    else
      record |> Map.keys() |> Enum.sort() |> keys_to_columns()
    end
  end

  defp columns_for_record(record) when is_list(record) do
    record |> Keyword.keys() |> keys_to_columns()
  end

  defp columns_for_record(_record) do
    # If the record is neither of the expected enumerables,
    # we treat it as a single column value
    keys_to_columns([:item])
  end

  @doc """
  Converts keys to column specifications.
  """
  @spec keys_to_columns(list(term())) :: list(Kino.Table.column())
  def keys_to_columns(keys) do
    Enum.map(keys, fn key -> %{key: key, label: inspect(key)} end)
  end

  @doc """
  Computes table column specifications for the given Ecto schema.
  """
  @spec columns_for_schema(module()) :: list(Kino.Table.column())
  def columns_for_schema(schema) do
    for field <- schema.__schema__(:fields) do
      type = schema.__schema__(:type, field)
      %{key: field, label: inspect(field), type: ecto_type_to_string(type)}
    end
  end

  defp ecto_type_to_string({:parameterized, module, _info}), do: inspect(module)
  defp ecto_type_to_string(type), do: inspect(type)

  @doc """
  Looks up record field value by key.
  """
  @spec get_field(record(), key :: term()) :: value :: term()
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
  Converts records to row specifications respecting the
  given columns.
  """
  @spec records_to_rows(list(record()), list(Kino.Table.column())) :: list(Kino.Table.row())
  def records_to_rows(records, columns) do
    for record <- records do
      fields =
        Map.new(columns, fn column ->
          value = get_field(record, column.key)
          {column.key, inspect(value)}
        end)

      %{fields: fields}
    end
  end

  @doc """
  Extracts schema module from the given struct or queryable.

  If no schema found, `nil` is returned.
  """
  @spec ecto_schema(queryable :: term()) :: module() | nil
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
