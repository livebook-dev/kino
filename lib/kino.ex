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
        |> Kino.VegaLite.start()
        |> Kino.render()

      Kino.VegaLite.push(widget, %{x: 1, y: 2})

  ### Kino.ETS

  `Kino.ETS` implements a data table output for ETS tables in the
  system:

      tid = :ets.new(:users, [:set, :public])
      Kino.ETS.start(tid)

  ### Kino.DataTable

  `Kino.DataTable` implements a data table output for user-provided
  tabular data:

      data = [
        %{id: 1, name: "Elixir", website: "https://elixir-lang.org"},
        %{id: 2, name: "Erlang", website: "https://www.erlang.org"}
      ]

      Kino.DataTable.start(data)

  ### Kino.Image

  `Kino.Image` wraps binary image content and can be used to render
  raw images of any given format:

      content = File.read!("/path/to/image.jpeg")
      Kino.Image.new(content, "image/jpeg")

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
  @spec render(term()) :: term()
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

    term
  end
end
