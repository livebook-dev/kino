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
            chunk: boolean(),
            style: style()
          }

  @type style :: [{:color | :font_weight | :font_size, String.Chars.t()}]

  @doc """
  Creates a new kino displaying the given text content.

  ## Options

    * `:terminal` - whether to render the text as if it were printed to
      standard output, supporting ANSI escape codes. Defaults to `false`

    * `:chunk` - whether this is a part of a larger text. Adjacent chunks
      are merged into a single text. This is useful for streaming content.
      Defaults to `false`

    * `:style` - a keyword list of CSS attributes, such as
      `style: [color: "#FF0000", font_weight: :bold]`. The currently supported
      styles are `:color`, `:font_size`, and `:font_weight`. Not supported on
      terminal outputs.

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
        when opts: [terminal: boolean(), chunk: boolean(), style: style()]
  def new(text, opts \\ []) when is_binary(text) do
    opts = Keyword.validate!(opts, terminal: false, chunk: false, style: [])
    terminal? = opts[:terminal]
    style = opts[:style]

    cond do
      not is_list(style) ->
        raise ArgumentError, ":style must be a keyword list"

      terminal? and style != [] ->
        raise ArgumentError, ":style not supported when terminal: true"

      true ->
        Enum.each(style, fn
          {key, value} when key in [:color, :font_weight, :font_size] ->
            if String.contains?(to_string(value), ";") do
              raise ArgumentError, "invalid CSS property value for #{inspect(key)}"
            end

          other ->
            raise ArgumentError,
                  ":style must be a keyword list of color/font_size/font_weight, got: #{inspect(other)}"
        end)
    end

    %__MODULE__{text: text, terminal: terminal?, chunk: opts[:chunk], style: style}
  end
end
