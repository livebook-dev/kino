defmodule Kino.Layout do
  @moduledoc """
  Layout utilities for arranging multiple kinos together.
  """

  defstruct [:type, :items, :info]

  @opaque t :: %__MODULE__{
            type: :tabs | :grid,
            items: list(term()),
            info: map()
          }

  @doc """
  Arranges outputs into separate tabs.

  ## Examples

      data = [
        %{id: 1, name: "Elixir", website: "https://elixir-lang.org"},
        %{id: 2, name: "Erlang", website: "https://www.erlang.org"}
      ]

      Kino.Layout.tabs([
        Table: Kino.DataTable.new(data),
        Raw: data
      ])

  """
  @spec tabs(list({String.t() | atom(), term()})) :: t()
  def tabs(tabs) when is_list(tabs) do
    {labels, terms} = Enum.unzip(tabs)
    labels = Enum.map(labels, &to_string/1)
    info = %{labels: labels}
    %Kino.Layout{type: :tabs, items: terms, info: info}
  end

  @doc """
  Arranges outputs into a grid.

  Note that the grid does not support scrolling, it always squeezes
  the content, such that it does not exceed the page width.

  ## Options

    * `:columns` - the number of columns in the grid. Optionally, supports
      a tuple of column width ratio, such as `{1, 2, 1}`, for three columns,
      where the middle one is twice as wide as the others. Defaults to `1`

    * `:boxed` - whether the grid should be wrapped in a bordered box.
      Defaults to `false`

    * `:gap` - the amount of spacing between grid items in pixels.
      Defaults to `8`

  ## Examples

      images =
        for path <- paths do
          path |> File.read!() |> Kino.Image.new(:jpeg)
        end

      Kino.Layout.grid(images, columns: 3)

  """
  @spec grid(list(term()), keyword()) :: t()
  def grid(terms, opts \\ []) when is_list(terms) do
    opts = Keyword.validate!(opts, columns: 1, boxed: false, gap: 8)

    info = %{
      columns: opts[:columns],
      boxed: opts[:boxed],
      gap: opts[:gap]
    }

    %Kino.Layout{type: :grid, items: terms, info: info}
  end
end
