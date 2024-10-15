defmodule Kino.Mermaid do
  @moduledoc ~S'''
  A kino for rendering Mermaid diagrams.

  > #### Relation to Kino.Markdown {: .info}
  >
  > Mermaid diagrams can also be generated dynamically with `Kino.Markdown`,
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
  Creates a new kino displaying the given Mermaid diagram.

  ## Options

    * `:caption` - an optional caption for the rendered diagram.

    * `:download` - whether or not to show a button for downloading
      the diagram as a SVG. Defaults to `true`.

  """
  @spec new(binary(), keyword()) :: t()
  def new(diagram, opts \\ []) do
    opts = Keyword.validate!(opts, caption: nil, download: true)

    Kino.JS.new(
      __MODULE__,
      %{diagram: diagram, caption: opts[:caption], download: opts[:download]},
      export: fn diagram -> {"mermaid", diagram} end
    )
  end
end
