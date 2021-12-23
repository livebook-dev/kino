defmodule Kino.JS.Live.Context do
  @moduledoc """
  State available in `Kino.JS.Live` server callbacks.
  """

  defstruct [:assigns, :__private__]

  @type t :: %__MODULE__{assigns: map(), __private__: map()}

  @doc false
  def new() do
    %__MODULE__{assigns: %{}, __private__: %{client_pids: []}}
  end
end
