defmodule Kino.JS.Live do
  @moduledoc ~S'''
  Introduces state and event-driven capabilities to JavaScript
  powered kinos.

  Make sure to read the introduction to JavaScript kinos in
  `Kino.JS` for more context.

  Similarly to static kinos, live kinos involve a custom JavaScript
  code running in the browser. In fact, this part of the API is the
  same. In addition, each live kino has a server process running on
  the Elixir side, responsible for maintaining state and able to
  communicate with the JavaScript side at any time. Again, to illustrate
  the ideas we start with a minimal example.

  ## Example

  We will follow up on our `KinoDocs.HTML` example by adding support
  for replacing the content on demand.

      defmodule KinoDocs.LiveHTML do
        use Kino.JS
        use Kino.JS.Live

        def new(html) do
          Kino.JS.Live.new(__MODULE__, html)
        end

        def replace(kino, html) do
          Kino.JS.Live.cast(kino, {:replace, html})
        end

        @impl true
        def init(html, ctx) do
          {:ok, assign(ctx, html: html)}
        end

        @impl true
        def handle_connect(ctx) do
          {:ok, ctx.assigns.html, ctx}
        end

        @impl true
        def handle_cast({:replace, html}, ctx) do
          broadcast_event(ctx, "replace", html)
          {:noreply, assign(ctx, html: html)}
        end

        asset "main.js" do
          """
          export function init(ctx, html) {
            ctx.root.innerHTML = html;

            ctx.handleEvent("replace", (html) => {
              ctx.root.innerHTML = html;
            });
          }
          """
        end
      end

  Just as before we define a module, this time calling it
  `KinoDocs.LiveHTML` for clarity. Note many similarities to
  the previous version, we still call `use Kino.JS`, define
  the `main.js` file and define the `new(html)` function for
  creating a kino instance. As a matter of fact, the initial
  result of `KinoDocs.LiveHTML.new(html)` will render exactly
  the same as our previous `KinoDocs.HTML.new(html)`.

  As for the new bits, we added `use Kino.JS.Live` to define
  a live kino server. We use `Kino.JS.Live.new/2` for creating
  the kino instance and we implement a few `GenServer`-like
  callbacks.

  Once the kino server is started with `Kino.JS.Live.new/2`,
  the `c:init/2` callback is called with the initial argument.
  In this case we store the given `html` in server state.

  Whenever the kino is rendered on a new client, the `c:handle_connect/1`
  callback is called and it builds the initial data for the
  client. In this case, we always return the stored `html`.
  This initial data is then passed to the JavaScript `init`
  function. Keep in mind that while the server is initialized
  once, connect may happen at any point, as the users join/refresh
  the page.

  Finally, the whole point of our example is the ability to
  replace the HTML content directly from the Elixir side and
  for this purpose we added the public `replace(kino, html)`
  function. Underneath the function uses `cast/2` to message
  our server and the message is handled with `c:handle_cast/2`.
  In this case we store the new `html` in the server state and
  broadcast an event with the new value. On the client side,
  we subscribe to those events with `ctx.handleEvent(event, callback)`
  to update the page accordingly.

  ## Event handlers

  You must eventually register JavaScript handlers for all events
  that the client may receive. However, the registration can be
  deferred, if the initialization is asynchronous. For example,
  the following is perfectly fine:

  ```js
  export function init(ctx, data) {
    fetch(data.someUrl).then((resp) => {
      ctx.handleEvent("update", (payload) => {
        // ...
      });
    });
  }
  ```

  Or alternatively:

  ```js
  export async function init(ctx, data) {
    const response = await fetch(data.someUrl);

    ctx.handleEvent("update", (payload) => {
      // ...
    });
  }
  ```

  In such case all incoming events are buffered and dispatched once
  the handler is registered.

  ## Binary payloads

  The client-server communication supports binary data, both on
  initialization and on custom events. On the server side, a binary
  payload has the form of `{:binary, info, binary}`, where `info`
  is regular JSON-serializable data that can be sent alongside
  the plain binary.

  On the client side, a binary payload is represented as `[info, buffer]`,
  where `info` is the additional data and `buffer` is the binary
  as `ArrayBuffer`.

  The following example showcases how to send and receive events
  with binary payloads.

      defmodule KinoDocs.Binary do
        use Kino.JS
        use Kino.JS.Live

        def new() do
          Kino.JS.Live.new(__MODULE__, nil)
        end

        @impl true
        def handle_connect(ctx) do
          payload = {:binary, %{message: "hello"}, <<1, 2>>}
          {:ok, payload, ctx}
        end

        @impl true
        def handle_event("ping", {:binary, _info, binary}, ctx) do
          reply_payload = {:binary, %{message: "pong"}, <<1, 2, binary::binary>>}
          broadcast_event(ctx, "pong", reply_payload)
          {:noreply, ctx}
        end

        asset "main.js" do
          """
          export function init(ctx, payload) {
            console.log("initial data", payload);

            ctx.handleEvent("pong", ([info, buffer]) => {
              console.log("event data", [info, buffer])
            });

            const buffer = new ArrayBuffer(2);
            const bytes = new Uint8Array(buffer);
            bytes[0] = 4;
            bytes[1] = 250;
            ctx.pushEvent("ping", [{ message: "ping" }, buffer]);
          }
          """
        end
      end
  '''

  defstruct [:module, :pid, :ref]

  alias Kino.JS.Live.Context

  @opaque t :: %__MODULE__{module: module(), pid: pid(), ref: Kino.Output.ref()}

  @type payload :: term() | {:binary, info :: term(), binary()}

  @doc """
  Invoked when the server is started.

  See `c:GenServer.init/1` for more details.

  > #### Starting other kinos {: .warning}
  >
  > It is generally not possible to start kinos inside the `c:init/2`
  > callback, as such operation would block forever. In case you need
  > to start other kinos during initialization, you must start them
  > beforehand and pass as an argument to `c:init/2`. So instead of
  >
  >     defmodule KinoDocs.Custom do
  >       def new() do
  >         Kino.JS.Live.new(__MODULE__, {})
  >       end
  >
  >       @impl true
  >       def init({}, ctx) do
  >         frame = Kino.Frame.new()
  >         {:ok, assign(ctx, frame: frame)}
  >       end
  >
  >       ...
  >     end
  >
  > do the following
  >
  >     defmodule KinoDocs.Custom do
  >       def new() do
  >         frame = Kino.Frame.new()
  >         Kino.JS.Live.new(__MODULE__, {frame})
  >       end
  >
  >       @impl true
  >       def init({frame}, ctx) do
  >         {:ok, assign(ctx, frame: frame)}
  >       end
  >
  >       ...
  >     end
  >
  > Also see `Kino.start_child/1`.
  """
  @callback init(arg :: term(), ctx :: Context.t()) ::
              {:ok, ctx :: Context.t()} | {:ok, ctx :: Context.t(), opts :: keyword()}

  @doc """
  Invoked whenever a new client connects to the server.

  The returned data is passed to the JavaScript `init` function
  of the connecting client.
  """
  @callback handle_connect(ctx :: Context.t()) :: {:ok, payload(), ctx :: Context.t()}

  @doc """
  Invoked to handle client events.
  """
  @callback handle_event(event :: String.t(), payload(), ctx :: Context.t()) ::
              {:noreply, ctx :: Context.t()}

  @doc """
  Invoked to handle asynchronous `cast/2` messages.

  See `c:GenServer.handle_cast/2` for more details.
  """
  @callback handle_cast(msg :: term(), ctx :: Context.t()) :: {:noreply, ctx :: Context.t()}

  @doc """
  Invoked to handle synchronous `call/3` messages.

  See `c:GenServer.handle_call/3` for more details.
  """
  @callback handle_call(msg :: term(), from :: term(), ctx :: Context.t()) ::
              {:noreply, ctx :: Context.t()} | {:reply, term(), ctx :: Context.t()}

  @doc """
  Invoked to handle all other messages.

  See `c:GenServer.handle_info/2` for more details.
  """
  @callback handle_info(msg :: term(), ctx :: Context.t()) :: {:noreply, ctx :: Context.t()}

  @doc """
  Invoked when the server is about to exit.

  See `c:GenServer.terminate/2` for more details.
  """
  @callback terminate(reason, ctx :: Context.t()) :: term()
            when reason: :normal | :shutdown | {:shutdown, term} | term

  @optional_callbacks init: 2,
                      handle_event: 3,
                      handle_call: 3,
                      handle_cast: 2,
                      handle_info: 2,
                      terminate: 2

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Kino.JS.Live

      import Kino.JS.Live.Context, only: [assign: 2, update: 3, broadcast_event: 3, send_event: 4]

      @before_compile Kino.JS.Live
    end
  end

  def __before_compile__(env) do
    unless Module.defines?(env.module, {:__assets_info__, 0}) do
      message = """
      make sure to include Kino.JS in #{inspect(env.module)} and define the necessary assets.

          use Kino.JS

      See Kino.JS for more details.
      """

      IO.warn(message, Macro.Env.stacktrace(env))
    end

    nil
  end

  @doc """
  Instantiates a live JavaScript kino defined by `module`.

  The given `init_arg` is passed to the `init/2` callback when
  the underlying kino process is started.
  """
  @spec new(module(), term()) :: t()
  def new(module, init_arg) do
    ref = Kino.Output.random_ref()
    {:ok, pid} = Kino.start_child({Kino.JS.Live.Server, {module, init_arg, ref}})
    %__MODULE__{module: module, pid: pid, ref: ref}
  end

  @doc false
  @spec js_info(t()) :: Kino.Output.js_info()
  def js_info(%__MODULE__{} = kino) do
    %{
      js_view: %{
        ref: kino.ref,
        pid: kino.pid,
        assets: kino.module.__assets_info__()
      },
      export: nil
    }
  end

  @doc """
  Sends an asynchronous request to the kino server.

  See `GenServer.cast/2` for more details.
  """
  @spec cast(t(), term()) :: :ok
  def cast(kino, term) do
    Kino.JS.Live.Server.cast(kino.pid, term)
  end

  @doc """
  Makes a synchronous call to the kino server and waits
  for its reply.

  See `GenServer.call/3` for more details.
  """
  @spec call(t(), term(), timeout()) :: term()
  def call(kino, term, timeout \\ 5_000) do
    Kino.JS.Live.Server.call(kino.pid, term, timeout)
  end
end
