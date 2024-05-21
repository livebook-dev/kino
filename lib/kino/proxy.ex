defmodule Kino.Proxy do
  @moduledoc """
  A kino for handling proxy requests from the host.

  ## Examples

      Kino.Proxy.listen(fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/text;charset=utf-8")
        |> Plug.Conn.send_resp(200, "used " <> conn.method <> " method")
      end)
  """

  @doc """
  Persists the function to be listened by the proxy handler.
  """
  @spec listen(atom(), module(), (Plug.Conn.t() -> Plug.Conn.t())) ::
          DynamicSupervisor.on_start_child()
  def listen(name \\ __MODULE__, mod \\ Livebook.Proxy.Handler, fun) when is_function(fun, 1) do
    Kino.start_child({mod, name: name, listen: fun})
  end
end
