defmodule Kino.Markdown do
  @moduledoc ~S'''
  A kino for rendering Markdown content.

  This is just a meta-struct that implements the `Kino.Render`
  protocol, so that it gets rendered as markdown.

  ## Examples

      Kino.Markdown.new("""
      # Example

      A regular Markdown file.

      ## Code

      ```elixir
      "Elixir" |> String.graphemes() |> Enum.frequencies()
      ```

      ## Table

      | ID | Name   | Website                 |
      | -- | ------ | ----------------------- |
      | 1  | Elixir | https://elixir-lang.org |
      | 2  | Erlang | https://www.erlang.org  |
      """)

  This format may come in handy when exploring Markdown
  from external sources:

      text = File.read!("/path/to/README.md")
      Kino.Markdown.new(text)
  '''

  @enforce_keys [:text, :chunk]

  defstruct [:text, :chunk]

  @opaque t :: %__MODULE__{
            text: String.t(),
            chunk: boolean()
          }

  @doc """
  Creates a new kino displaying the given Markdown content.

  ## Options

    * `:chunk` - whether this is a part of a larger text. Adjacent chunks
      are merged into a single text. This is useful for streaming content.
      Defaults to `false`

  """
  @spec new(binary(), keyword()) :: t()
  def new(text, opts \\ []) do
    opts = Keyword.validate!(opts, chunk: false)
    %__MODULE__{text: text, chunk: opts[:chunk]}
  end
end
