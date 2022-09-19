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

      content = File.read!("/path/to/README.md")
      Kino.Markdown.new(content)
  '''

  @enforce_keys [:content]

  defstruct [:content]

  @opaque t :: %__MODULE__{
            content: binary()
          }

  @doc """
  Creates a new kino displaying the given Markdown content.
  """
  @spec new(binary()) :: t()
  def new(content) do
    %__MODULE__{content: content}
  end
end
