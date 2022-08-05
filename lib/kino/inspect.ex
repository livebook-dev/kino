defmodule Kino.Inspect do
  @moduledoc """
  A struct wrapping any term for default rendering.

  This is just a meta-struct that implements the `Kino.Render`
  protocol, so that the wrapped value is rendered using the inspect
  protocol.
  """

  defstruct [:term]

  @opaque t :: %__MODULE__{term: term()}

  @doc """
  Wraps the given term.
  """
  @spec new(term()) :: t()
  def new(term), do: %__MODULE__{term: term}
end
