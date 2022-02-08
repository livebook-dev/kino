defmodule Kino.Explorer do
  @moduledoc """
  A widget for interactively viewing `Explorer.DataFrame`.

  ## Examples

      df = Explorer.Datasets.fossil_fuels()
      Kino.Explorer.new(df)
  """

  @behaviour Kino.Table

  @type t :: Kino.JS.Live.t()

  @compile {:no_warn_undefined, Explorer.DataFrame}

  @doc """
  Starts a widget process representing the given data frame.
  """
  @spec new(Explorer.DataFrame.t()) :: t()
  def new(df) do
    unless Code.ensure_loaded?(Explorer.DataFrame) do
      raise "Explorer is missing"
    end

    Kino.Table.new(__MODULE__, {df})
  end

  @impl true
  def init({df}) do
    total_rows = Explorer.DataFrame.n_rows(df)

    names = Explorer.DataFrame.names(df)
    dtypes = Explorer.DataFrame.dtypes(df)

    columns =
      names
      |> Enum.zip(dtypes)
      |> Enum.map(fn {name, dtype} ->
        %{key: name, label: to_string(name), type: to_string(dtype)}
      end)

    info = %{name: "DataFrame", features: [:pagination, :sorting]}

    {:ok, info, %{df: df, total_rows: total_rows, columns: columns}}
  end

  @impl true
  def get_data(rows_spec, state) do
    records = get_records(state.df, rows_spec)
    rows = Enum.map(records, &record_to_row/1)
    {:ok, %{columns: state.columns, rows: rows, total_rows: state.total_rows}, state}
  end

  defp get_records(df, rows_spec) do
    df =
      if order_by = rows_spec[:order_by] do
        Explorer.DataFrame.arrange(df, [{rows_spec.order, order_by}])
      else
        df
      end

    df = Explorer.DataFrame.slice(df, rows_spec.offset, rows_spec.limit)

    {cols, lists} = df |> Explorer.DataFrame.to_map() |> Enum.unzip()
    col_names = Enum.map(cols, &to_string/1)

    lists
    |> Enum.zip()
    |> Enum.map(fn row ->
      Enum.zip(col_names, Tuple.to_list(row))
    end)
  end

  defp record_to_row(record) do
    fields = Map.new(record, fn {col_name, value} -> {col_name, to_string(value)} end)
    %{fields: fields}
  end
end
