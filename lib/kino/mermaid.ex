defmodule Kino.Mermaid do
  @moduledoc ~S'''
  A kino for rendering Mermaid graphs.

  > #### Relation to Kino.Markdown {: .info}
  >
  > Mermaid graphs can also be generated dynamically with `Kino.Markdown`,
  > however the output of `Kino.Markdown` is never persisted in the
  > notebook source. `Kino.Mermaid` doesn't have this limitation.

  ## Examples

      Kino.Mermaid.new("""
      graph TD;
        A-->B;
        A-->C;
        B-->D;
        C-->D;
      """)

  '''

  use Kino.JS, assets_path: "lib/assets/mermaid/build"

  @type t :: Kino.JS.t()

  @doc """
  Creates a new kino displaying the given Mermaid graph.
  """
  @spec new(binary(), Keyword.t()) :: t()
  def new(content, options \\ []) do
    options = Keyword.validate!(options, [:title])
    title = Keyword.get(options, :title, "diagram")
    Kino.JS.new(__MODULE__, %{content: content, title: title}, export: fn content -> {"mermaid", content} end)
  end
end
