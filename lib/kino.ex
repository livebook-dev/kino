defmodule Kino do
  @moduledoc """
  Interactive widgets for Livebook.
  """

  @doc """
  Sends the given term as cell output.

  You can think of this function as a generalized
  `IO.puts/2` that works for any type and is rendered
  by Livebook similarly to regular evaluation results.

  ## Examples

  Arbitrary data structure

      Kino.render([%{name: "Jake Peralta"}, %{name: "Amy Santiago"}])

  VegaLite plot

      Vl.new(...)
      |> Vl.data_from_series(...)
      |> ...
      |> Kino.render()

      # more code

  Widgets

      vl_widget =
        Vl.new(...)
        |> Vl.data_from_series(...)
        |> ...
        |> Kino.VegaLite.start()

      Kino.render(vl_widget)

      # stream data to the plot
  """
  @spec render(term()) :: term()
  def render(term) do
    ref = make_ref()

    send(Process.group_leader(), {:io_request, self(), ref, {:livebook_put_term, term}})

    receive do
      {:io_reply, ^ref, :ok} -> :ok
      {:io_reply, ^ref, _} -> :error
    end

    term
  end
end
