defmodule Kino.Text do
  @moduledoc ~S'''
  A kino for rendering plain text content.

  For rich text use `Kino.Markdown`.

  ## Examples

      Kino.Text.new("Hello!")

  '''

  @enforce_keys [:content]

  defstruct [:content]

  @opaque t :: %__MODULE__{
            content: binary()
          }

  @doc """
  Creates a new kino displaying the given text content.
  """
  @spec new(binary()) :: t()
  def new(content) do
    %__MODULE__{content: content}
  end
end
