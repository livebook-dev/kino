defmodule Kino.Proxy do
  @moduledoc """
  Functionality for handling proxy requests forwarded from Livebook.

  Livebook proxies requests at the following paths:

    * `/proxy/sessions/:id/*path` - a notebook session

    * `/proxy/apps/:slug/sessions/:session_id/*path` - a specific app session

    * `/proxy/apps/:slug/*path` - generic app path, only supported for
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
  >   expected_token = "my-secret-api-token"
  >
  >   with ["Bearer " <> user_token] <- Plug.Conn.get_req_header(conn, "authorization"),
  >        true <- Plug.Crypto.secure_compare(user_token, expected_token) do
  >     Plug.Conn.send_resp(conn, 200, "hello")
  >   else
  >     _ ->
  >       conn
  >       |> Plug.Conn.put_resp_header("www-authenticate", "Bearer")
  >       |> Plug.Conn.send_resp(401, "Unauthorized")
  >   end
  > end)
  > ```
  """

  @type plug() ::
          (Plug.Conn.t() -> Plug.Conn.t())
          | module()
          | {module(), term()}

  @doc """
  Registers a request listener.

  Expects the listener to be a plug, that is, one of:

    * a function plug: a `fun(conn)` function that takes a `Plug.Conn` and returns a `Plug.Conn`.

    * a module plug: a `module` atom or a `{module, options}` tuple.
  """
  @spec listen(plug()) :: DynamicSupervisor.on_start_child()
  def listen(plug) do
    unless Code.ensure_loaded?(Plug) do
      raise """
      Plug is required as a dependency to use Kino.Proxy. Please add the following to your Mix.install/2:

          {:plug, "~> 1.16"}

      """
    end

    fun =
      case plug do
        fun when is_function(fun, 1) ->
          fun

        mod when is_atom(mod) ->
          opts = mod.init([])
          &mod.call(&1, opts)

        {mod, opts} when is_atom(mod) ->
          opts = mod.init(opts)
          &mod.call(&1, opts)

        other ->
          raise """
          expected plug to be one of:

            * fun(conn)
            * module
            * {module, options}

          got: #{inspect(other)}
          """
      end

    case Kino.Bridge.get_proxy_handler_child_spec(fun) do
      {:ok, child_spec} ->
        Kino.start_child(child_spec)

      {:request_error, reason} ->
        raise "failed to access the proxy handler child spec, reason: #{inspect(reason)}"
    end
  end
end
