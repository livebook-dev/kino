defmodule Kino.Text do
  @moduledoc ~S'''
  A kino for rendering text content.

  For rich text, use `Kino.Markdown`.

  ## Examples

      Kino.Text.new("Hello!")

      [:green, "Hello!"]
      |> IO.ANSI.format()
      |> IO.iodata_to_binary()
      |> Kino.Text.new(terminal: true)

  '''

  @enforce_keys [:text]

  defstruct [:text, :terminal, :chunk]

  @opaque t :: %__MODULE__{
            text: String.t(),
            terminal: boolean(),
            chunk: boolean()
          }

  @doc """
  Creates a new kino displaying the given text content.

  ## Options

    * `:terminal` - whether to render the text as if it were printed to
      standard output, supporting ANSI escape codes. Defaults to `false`

    * `:chunk` - whether this is a part of a larger text. Adjacent chunks
      are merged into a single text. This is useful for streaming content.
      Defaults to `false`

  ## Examples

  ### Using the `:chunk` option

  Using a `Kino.Frame`.

      frame = Kino.Frame.new() |> Kino.render()

      for word <- ["who", " let", " the", " dogs", " out"] do
        text = Kino.Text.new(word, chunk: true)
        Kino.Frame.append(frame, text)
        Process.sleep(250)
      end

  Without using a `Kino.Frame`.

      for word <- ["who", " let", " the", " dogs", " out"] do
        Kino.Text.new(word, chunk: true) |> Kino.render()
        Process.sleep(250)
      end

      Kino.nothing()

  """
  @spec new(String.t(), opts) :: t() when opts: [terminal: boolean(), chunk: boolean()]
  def new(text, opts \\ []) when is_binary(text) do
    opts = Keyword.validate!(opts, terminal: false, chunk: false)
    %__MODULE__{text: text, terminal: opts[:terminal], chunk: opts[:chunk]}
  end
end
