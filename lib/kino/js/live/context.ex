defmodule Kino.JS.Live.Context do
  @moduledoc """
  State available in `Kino.JS.Live` server callbacks.
  """

  defstruct [:assigns, :events]

  @type t :: %__MODULE__{assigns: map(), events: list()}

  @doc false
  def new() do
    %__MODULE__{assigns: %{}, events: []}
  end
end
