defmodule Kino.Proxy do
  @moduledoc """
  Functionality for handling proxy requests forwarded from Livebook.

  This functionality will make the requests forwarded from Livebook
  through a proxy handler and send the response to the incoming connection
  according to user definition.

  The proxy handler supports the routes below to perform this proxy
  between the `Livebook` and current runtime:

    * `/sessions/:id/proxy/*path` - for notebook sessions.

    * `/apps/:slug/:session_id/proxy/*path` - for app sessions.

  Only certain fields will be forwarded through the proxy handler, which
  builds a new `%Plug.Conn{}` and sends to the listener function.

    * `:host`
    * `:method`
    * `:owner`
    * `:port`
    * `:remote_ip`
    * `:query_string`
    * `:path_info`
    * `:scheme`
    * `:script_name`
    * `:req_headers`

  It is possible to create notebooks and apps as APIs, allowing the user to fetch the
  request data and send a proper response.

      data = <<...>>
      token = "auth-token"

      Kino.Proxy.listen(fn
        %{path_info: ["export", "data"]} = conn ->
          ["Bearer " <> ^token] = Plug.Conn.get_req_header(conn, "authorization")

          conn
          |> Plug.Conn.put_resp_header("content-type", "application/csv")
          |> Plug.Conn.send_resp(200, data)

        conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/text")
          |> Plug.Conn.send_resp(200, "use /export/data to get extract the report data")
      end)

  So you would need to access the `/sessions/:id/proxy/export/data` to extract the data from
  your session and return as a body response.
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
