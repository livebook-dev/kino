defmodule Kino do
  @moduledoc """
  Client-driven interactive widgets for Livebook.

  Kino is the library used by Livebook to render rich and interactive
  output directly from your Elixir code.

  Kino renders any data structure that implements the `Kino.Render`
  protocol, falling back to the `inspect/2` representation whenever
  an implementation is not available. The data structures supported
  by Kino out of the box are:

  ### [VegaLite](https://github.com/elixir-nx/vega_lite) widgets

      Vl.new(...)
      |> Vl.data_from_series(...)
      |> ...

  ### [Kino.VegaLite](https://github.com/elixir-nx/vega_lite) widgets

  `Kino.VegaLite` is an extension of `VegaLite` that allows data to
  be streamed:

      widget =
        Vl.new(...)
        |> Vl.data_from_series(...)
        |> ...
        |> Kino.VegaLite.start()
        |> Kino.render()

      Kino.VegaLite.push(widget, %{x: 1, y: 2})

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
