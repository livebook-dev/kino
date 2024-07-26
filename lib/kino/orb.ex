defmodule Kino.Orb do
  @moduledoc ~S'''
  A kino for rendering big graphs.


  ## Examples

  nodes = [
        %{ id: 1, label: "Orb" },
        %{ id: 2, label: "Graph" },
        %{ id: 3, label: "Canvas" },
      ]
  edges = [
        %{ id: 1, start: 1, end: 2, label: "DRAWS" },
        %{ id: 2, start: 2, end: 3, label: "ON" },
      ]
  Kino.Orb.new(%{nodes: nodes,edges: edges})


  count = 600

  nodes = [
        %{ id: 1, label: "Orb" },
        %{ id: 2, label: "Graph" },
        %{ id: 3, label: "Canvas" },
      ] ++ Enum.map(4..count, fn i ->
        %{ id: i, label: "#{i}"}
      end)
  edges = [
        %{ id: 1, start: 1, end: 2, label: "DRAWS" },
        %{ id: 2, start: 2, end: 3, label: "ON" },
      ] ++ Enum.map(4..count, fn i ->
        %{ id: i, start: 1, end: i, label: "#{i}"}
      end)
  Kino.Orb.new(%{nodes: nodes,edges: edges})

  '''

  use Kino.JS, assets_path: "lib/assets/orb/build"

  @type t :: Kino.JS.t()

  @doc """
  Creates a new kino displaying the given graph.
  """
  @spec new(binary()) :: t()
  def new(content) do
    Kino.JS.new(__MODULE__, content, export: fn content -> {"orb", content} end)
  end
end
