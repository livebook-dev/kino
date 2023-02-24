defmodule Kino.HTML do
  @moduledoc ~S'''
  A kino for rendering HTML content.

  The HTML may include `<script>` tags with global JS to be executed.

  In case you need to parameterize the HTML with dynamic values, write
  a custom `Kino.JS` component.

  ## Examples

      Kino.HTML.new("""
      <h3>Look!</h3>

      <p>I wrote this HTML from <strong>Kino</strong>!</p>
      """)

      Kino.HTML.new("""
      <button id="button">Click</button>

      <script>
        const button = document.querySelector("#button");

        button.addEventListener("click", (event) => {
          button.textContent = "Clicked!"
        });
      </script>
      """)

  '''

  use Kino.JS

  @type t :: Kino.JS.t()

  @doc """
  Creates a new kino displaying the given HTML.
  """
  @spec new(String.t()) :: t()
  def new(html) when is_binary(html) do
    Kino.JS.new(__MODULE__, html)
  end

  asset "main.js" do
    """
    export function init(ctx, html) {
      setInnerHTML(ctx.root, html);
    }

    function setInnerHTML(element, html) {
      // By default setting inner HTML doesn't execute scripts, as
      // noted in [1], however we can work around this by explicitly
      // building the script element.
      //
      // [1]: https://developer.mozilla.org/en-US/docs/Web/API/Element/innerHTML#security_considerations

      element.innerHTML = html;

      Array.from(element.querySelectorAll("script")).forEach((scriptEl) => {
        const safeScriptEl = document.createElement("script");

        Array.from(scriptEl.attributes).forEach((attr) => {
          safeScriptEl.setAttribute(attr.name, attr.value)
        });

        const scriptText = document.createTextNode(scriptEl.innerHTML);
        safeScriptEl.appendChild(scriptText);

        scriptEl.parentNode.replaceChild(safeScriptEl, scriptEl);
      });
    }
    """
  end
end
