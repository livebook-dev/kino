defmodule Kino.Proxy do
  @moduledoc """
  Functionality for handling proxy requests forwarded from Livebook.

  Livebook proxies requests at the following paths:

    * `/sessions/:id/proxy/*path` - a notebook session

    * `/apps/:slug/:session_id/proxy/*path` - a specific app session

    * `/apps/:slug/proxy/*path` - generic app path, only supported for
      single-session apps. If the app has automatic shutdowns enabled
      and it is not currently running, it will be automatically started

  You can define a custom listener to handle requests at these paths.
  The listener receives a `Plug.Conn` and it should use the `Plug` API
  to send the response, for example:

      Kino.Proxy.listen(fn conn ->
        Plug.Conn.send_resp(conn, 200, "hello")
      end

  > #### Plug dependency {: .info}
  >
  > In order to use this feature, you need to add `:plug` as a dependency.

  ## Examples

  Using the proxy feature, we can use Livebook apps to build APIs.
  For example, we could provide a data export endpoint:


      Kino.Proxy.listen(fn
        %{path_info: ["export", "data"]} = conn ->
          data = "some data"

          conn
          |> Plug.Conn.put_resp_header("content-type", "application/csv")
          |> Plug.Conn.send_resp(200, data)

        conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/text")
          |> Plug.Conn.send_resp(200, "use /export/data to get extract the report data")
      end)

  Once deployed as an app, the API client would be able to export the data
  by sending a request to `/apps/:slug/proxy/export/data`.

  > #### Authentication {: .warning}
  >
  > The paths exposed by `Kino.Proxy` don't use the authentication mechanisms
  > defined in your Livebook instance.
  >
  > If you need to authenticate requests, you should
  > implement your own authentication mechanism. Here's a simple example.
  >
  > ```elixir
  > Kino.Proxy.listen(fn conn ->
  >   import Plug.BasicAuth
  >
  >   case Plug.BasicAuth.basic_auth(conn, username: "username", password: "password") do
  >     %{status: 401} = conn -> Plug.Conn.send_resp(conn)
  >
  >     conn -> Plug.Conn.send_resp(conn, 200, "hello")
  >   end
  > end)
  > ```
  """

  @doc """
  Registers a request listener.

  Expects the listener to be a function that handles a request
  `Plug.Conn`.
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
