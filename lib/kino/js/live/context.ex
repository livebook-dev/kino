defmodule Kino.JS.Live.Context do
  @moduledoc """
  State available in `Kino.JS.Live` server callbacks.

  ## Properties

    * `:assigns` - custom server state kept across callback calls

    * `:origin` - an opaque identifier of the client that triggered
      the given action. It is set in `c:Kino.JS.Live.handle_connect/1`
      and `c:Kino.JS.Live.handle_event/3`
  """

  defstruct [:assigns, :origin, :__private__]

  @type t :: %__MODULE__{assigns: map(), origin: origin(), __private__: map()}

  @type origin :: nil | term()

  @doc false
  def new() do
    %__MODULE__{assigns: %{}, origin: nil, __private__: %{client_pids: []}}
  end
end
