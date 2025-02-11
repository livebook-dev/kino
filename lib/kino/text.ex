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

  defstruct [:text, :terminal, :chunk, :style]

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

    * `:style` - a keyword list or map of pairs HTML styles, such as
      `style: [color: "#FF0000", font_weight: :bold]`. Atom keys are
      automatically from snake case (`font_weight`) to kebab case
      (`font-weight`). Not supported on terminal outputs.

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
  @spec new(String.t(), opts) :: t()
        when opts: [terminal: boolean(), chunk: boolean(), style: Enumerable.t()]
  def new(text, opts \\ []) when is_binary(text) do
    opts = Keyword.validate!(opts, terminal: false, chunk: false, style: nil)
    terminal? = opts[:terminal]

    style =
      if terminal? do
        if opts[:style] do
          raise ArgumentError, ":style not supported when :terminal true"
        end
      else
        style = opts[:style] || []

        Enum.each(style, fn
          {key, value} when is_binary(key) or is_atom(key) ->
            true

          other ->
            raise ArgumentError, ":style must be a map or keyword list, got: #{inspect(other)}"
        end)

        style
      end

    %__MODULE__{text: text, terminal: terminal?, chunk: opts[:chunk], style: style}
  end
end
