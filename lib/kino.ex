defmodule Kino do
  @moduledoc """
  Client-driven interactive widgets for Livebook.

  Kino is the library used by Livebook to render rich and interactive
  output directly from your Elixir code.

  Kino renders any data structure that implements the `Kino.Render`
  protocol, falling back to the `inspect/2` representation whenever
  an implementation is not available. The data structures supported
  by Kino out of the box are:

  ### VegaLite

  `VegaLite` specifications are rendered as visualizations:

      Vl.new(...)
      |> Vl.data_from_series(...)
      |> ...

  ### Kino.VegaLite

  `Kino.VegaLite` is an extension of `VegaLite` that allows data to
  be streamed:

      widget =
        Vl.new(...)
        |> Vl.data_from_series(...)
        |> ...
        |> Kino.VegaLite.new()
        |> tap(&Kino.render/1)

      Kino.VegaLite.push(widget, %{x: 1, y: 2})

  ### Kino.ETS

  `Kino.ETS` implements a data table output for ETS tables in the
  system:

      tid = :ets.new(:users, [:set, :public])
      Kino.ETS.new(tid)

  ### Kino.DataTable

  `Kino.DataTable` implements a data table output for user-provided
  tabular data:

      data = [
        %{id: 1, name: "Elixir", website: "https://elixir-lang.org"},
        %{id: 2, name: "Erlang", website: "https://www.erlang.org"}
      ]

      Kino.DataTable.new(data)

  ### Kino.Image

  `Kino.Image` wraps binary image content and can be used to render
  raw images of any given format:

      content = File.read!("/path/to/image.jpeg")
      Kino.Image.new(content, "image/jpeg")

  ### Kino.Markdown

  `Kino.Markdown` wraps Markdown content for richer text rendering.

      Kino.Markdown.new(\"\"\"
      # Example

      A regular Markdown file.

      ## Code

      ```elixir
      "Elixir" |> String.graphemes() |> Enum.frequencies()
      ```

      ## Table

      | ID | Name   | Website                 |
      | -- | ------ | ----------------------- |
      | 1  | Elixir | https://elixir-lang.org |
      | 2  | Erlang | https://www.erlang.org  |
      \"\"\")

  ### Kino.Ecto

  `Kino.Ecto` implements a data table output for arbitrary
  `Ecto` queries:

      Kino.Ecto.new(Weather, Repo)

  ### All others

  All other data structures are rendered as text using Elixir's
  `inspect/2`.
  """

  @doc """
  Sends the given term as cell output.

  This allows any Livebook cell to have multiple evaluation
  results. You can think of this function as a generalized
  `IO.puts/2` that works for any type.
  """
  @spec render(term()) :: :"do not show this result in output"
  def render(term) do
    gl = Process.group_leader()
    ref = Process.monitor(gl)
    output = Kino.Render.to_livebook(term)

    send(gl, {:io_request, self(), ref, {:livebook_put_output, output}})

    receive do
      {:io_reply, ^ref, :ok} -> :ok
      {:io_reply, ^ref, _} -> :error
      {:DOWN, ^ref, :process, _object, _reason} -> :error
    end

    Process.demonitor(ref)

    :"do not show this result in output"
  end

  @doc """
  Configures Kino.

  The supported options are:

    * `:inspect`

  They are discussed individually in the sections below.

  ## Inspect

  A keyword list containing inspect options used for printing
  usual evaluation results. Defaults to pretty formatting with
  a limit of 50 entries.

  To show more entries, you configure a higher limit:

      Kino.configure(inspect: [limit: 200])

  You can also show all entries by setting the limit to `:infinity`,
  but keep in mind that for large data structures it is memory-expensive
  and is not an advised configuration in this case. Instead prefer
  the use of `IO.inspect/2` with `:infinity` limit when needed.

  See `Inspect.Opts` for the full list of options.
  """
  @spec configure(keyword()) :: :ok
  def configure(options) do
    Kino.Config.configure(options)
  end
end
