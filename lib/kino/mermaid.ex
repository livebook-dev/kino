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

  @download_defaults [title: "Diagram", filename: "diagram.svg"]

  @doc """
  Creates a new kino displaying the given Mermaid diagram.

  ## Options

    * `:caption` - an optional caption for the rendered diagram. Defaults to `false`.

    * `:download` - whether or not to allow downloading the rendered Mermaid svg.
    Defaults to `true`.

      Downloads can be further customized by providing a keyword list
      instead of a boolean, containing:

      * `:title` - The alt text displayed for the download button.
      * `:filename` - The name of the file to be downloaded.

  """
  @spec new(binary(), keyword()) :: t()
  def new(diagram, opts \\ []) do
    opts = Keyword.validate!(opts, caption: false, download: true)

    download =
      case Keyword.fetch!(opts, :download) do
        true ->
          Map.new(@download_defaults)

        download_opts when is_list(download_opts) ->
          download_opts
          |> Keyword.validate!(@download_defaults)
          |> Map.new()

        _ ->
          false
      end

    caption = Keyword.fetch!(opts, :caption)

    Kino.JS.new(__MODULE__, %{diagram: diagram, caption: caption, download: download},
      export: fn diagram -> {"mermaid", diagram} end
    )
  end
end
