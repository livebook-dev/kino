defmodule Kino.Text do
  @moduledoc ~S'''
  A kino for rendering text content.

  For rich text, use `Kino.Markdown`.

  ## Examples

      Kino.Text.new("Hello!")

      [:green, "Hello!"]
      |> IO.ANSI.format()
      |> IO.iodata_to_binary()
      |> Kino.Text.new(console: true)

  '''

  @enforce_keys [:content]

  defstruct [:content, console: false]

  @opaque t :: %__MODULE__{
            content: binary(),
            console: boolean()
          }

  @doc """
  Creates a new kino displaying the given text content.

  ## Options

    * `:console` - whether to render the text as if it were printed to
      standard output, supporting ANSI escape codes. Defaults to `false`
  """
  @spec new(String.t(), opts) :: t() when opts: [console: boolean()]
  def new(content, opts \\ []) when is_binary(content) do
    %__MODULE__{content: content, console: Keyword.get(opts, :console, false)}
  end
end
