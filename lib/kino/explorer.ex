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
    dtypes = Explorer.DataFrame.dtypes(df)
    summaries = summary(df)

    columns =
      Enum.map(dtypes, fn {name, dtype} ->
        %{
          key: name,
          label: to_string(name),
          type: type_of(dtype),
          summary: summaries[String.to_atom(name)]
        }
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
        Explorer.DataFrame.arrange_with(df, &[{rows_spec.order, &1[order_by]}])
      else
        df
      end

    df = Explorer.DataFrame.slice(df, rows_spec.offset, rows_spec.limit)

    {cols, lists} = df |> Explorer.DataFrame.to_columns() |> Enum.unzip()
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

  defp summary(df) do
    describe =
      df
      |> Explorer.DataFrame.describe()
      |> Explorer.DataFrame.slice([1, 3, 7])
      |> Explorer.DataFrame.to_columns()
      |> Map.delete("describe")

    df_series = Explorer.DataFrame.to_series(df)

    for {column, [mean, min, max]} <- describe,
        series = Map.get(df_series, column),
        type = get_type(series),
        freq = get_freq(series) do
      %{
        min: min,
        max: max,
        mean: mean,
        nulls: Explorer.Series.nil_count(series),
        top: get_top(freq),
        top_freq: get_top_freq(freq),
        unique: get_unique(series)
      }
      |> format_summary(column, type)
    end
  end

  defp get_freq(data) do
    data
    |> Explorer.Series.frequencies()
    |> Explorer.DataFrame.head(1)
    |> Explorer.DataFrame.to_columns()
  end

  defp get_top(%{"values" => [top]}), do: top

  defp get_top_freq(%{"counts" => [top_freq]}), do: top_freq

  defp get_type(data) do
    if Explorer.Series.dtype(data) in [:float, :integer], do: :numeric, else: :categorical
  end

  defp get_unique(data) do
    data |> Explorer.Series.distinct() |> Explorer.Series.count()
  end

  defp format_summary(summary, column, :categorical) do
    {String.to_atom(column), Map.take(summary, [:unique, :top, :top_freq, :nulls])}
  end

  defp format_summary(summary, column, :numeric) do
    summary = %{summary | mean: Float.round(summary.mean, 2)}
    {String.to_atom(column), Map.take(summary, [:min, :max, :mean, :nulls])}
  end

  defp type_of(:integer), do: "number"
  defp type_of(:float), do: "number"
  defp type_of(_), do: "text"
end
