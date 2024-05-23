defmodule Kino.Proxy do
  @moduledoc """
  Functionality for handling proxy requests forwarded from Livebook.

  TODO: Write an extensive docs here.
  """

  @doc """
  Persists the function to be listened by the proxy handler.
  """
  @spec listen((Plug.Conn.t() -> Plug.Conn.t())) :: DynamicSupervisor.on_start_child()
  def listen(fun) when is_function(fun, 1) do
    case Kino.Bridge.get_proxy_handler_child_spec(fun) do
      {:ok, child_spec} ->
        Kino.start_child(child_spec)

      {:request_error, reason} ->
        raise "failed to access the proxy handler child spec, reason: #{inspect(reason)}"
    end
  end
end
