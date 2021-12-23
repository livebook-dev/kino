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

  @doc """
  Stores key-value pairs in the state.

  ## Examples

      assign(ctx, count: 1, timestamp: DateTime.utc_now())
  """
  @spec assign(t(), Enumerable.t()) :: t()
  def assign(%__MODULE__{} = ctx, assigns) do
    assigns =
      Enum.reduce(assigns, ctx.assigns, fn {key, val}, assigns ->
        Map.put(assigns, key, val)
      end)

    %{ctx | assigns: assigns}
  end

  @doc """
  Updates an existing key with the given function in the state.

  ## Examples

      assign(ctx, count: 1, timestamp: DateTime.utc_now())
  """
  @spec update(t(), term(), (term() -> term())) :: t()
  def update(%__MODULE__{} = ctx, key, fun) when is_function(fun, 1) do
    val = Map.fetch!(ctx.assigns, key)
    assign(ctx, [{key, fun.(val)}])
  end

  @doc """
  Sends an event to the client.

  The event is dispatched to the registered JavaScript callback
  on all connected clients.

  ## Examples

      broadcast_event(ctx, "new_point", %{x: 10, y: 10})
  """
  def broadcast_event(%__MODULE__{} = ctx, event, payload \\ nil) when is_binary(event) do
    update_in(ctx, [Access.key!(:events)], &[{event, payload} | &1])
  end
end
