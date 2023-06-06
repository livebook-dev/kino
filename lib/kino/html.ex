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

  use Kino.JS, assets_path: "lib/assets/html"

  @type t :: Kino.JS.t()

  @doc """
  Creates a new kino displaying the given HTML.
  """
  @spec new(String.t()) :: t()
  def new(html) when is_binary(html) do
    Kino.JS.new(__MODULE__, html)
  end
end
