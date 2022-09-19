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

  use Kino.JS

  @type t :: Kino.JS.t()

  @doc """
  Creates a new kino displaying the given Mermaid graph.
  """
  @spec new(binary()) :: t()
  def new(content) do
    Kino.JS.new(__MODULE__, content, export_info_string: "mermaid")
  end

  asset "main.js" do
    """
    import "https://cdn.jsdelivr.net/npm/mermaid@9.1.3/dist/mermaid.min.js";

    mermaid.initialize({ startOnLoad: false });

    export function init(ctx, content) {
      function render() {
        mermaid.render("graph1", content, (svgSource, bindListeners) => {
          ctx.root.innerHTML = svgSource;
          bindListeners && bindListeners(ctx.root);

          // A workaround for https://github.com/mermaid-js/mermaid/issues/1758
          const svg = ctx.root.querySelector("svg");
          svg.removeAttribute("height");
        });
      }

      // If the JS view is not visible, defer initialization until it becomes visible
      if (window.innerWidth === 0) {
        window.addEventListener("resize", () => render(), { once: true });
      } else {
        render();
      }
    }
    """
  end
end
