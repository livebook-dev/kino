defmodule Kino.JS.Live do
  @moduledoc ~S'''
  Introduces state and event-driven capabilities to JavaScript
  powered widgets.

  Make sure to read the introduction to JavaScript widgets in
  `Kino.JS` for more context.

  Similarly to static widgets, live widgets involve a custom
  JavaScript code running in the browser. In fact, this part
  of the API is the same. In addition, each live widget has
  a server process running on the Elixir side, responsible for
  maintaining state and able to communicate with the JavaScript
  side at any time. Again, to illustrate the ideas we start
  with a minimal example.

  ## Example

  We will follow up on our `Kino.HTML` example by adding support
  for replacing the content on demand.

      defmodule Kino.LiveHTML do
        use Kino.JS
        use Kino.JS.Live

        def new(html) do
          Kino.JS.Live.new(__MODULE__, html)
        end

        def replace(widget, html) do
          Kino.JS.Live.cast(widget, {:replace, html})
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
          {:noreply, ctx |> broadcast_event("replace", html) |> assign(html: html)}
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
  `Kino.LiveHTML` for clarity. Note many similarities to the
  previous version, we still call `use Kino.JS`, define the
  `main.js` file and define the `new(html)` function for
  building the widget. As a matter of fact, the initial result
  of `Kino.LiveHTML.new(html)` will render exactly the same
  as our previous `Kino.HTMl.new(html)`.

  As for the new bits, we added `use Kino.JS.Live` to define
  a live widget server. We use `Kino.JS.Live.new/2` for creating
  the widget instance and we implement a few `GenServer`-like
  callbacks.

  Once the widget server is started with `Kino.JS.Live.new/2`,
  the `c:init/2` callback is called with the initial argument.
  In this case we store the given `html` in server state.

  Whenever the widget is rendered on the client, the `c:handle_connect/1`
  callback is called and it builds the initial data for the
  client. In this case, we always return the stored `html`.
  This initial data is then passed to the JavaScript `init`
  function. Keep in mind that while the server is initialized
  once, connect may happen at any point, as the users join/refresh
  the page.

  Finally, the whole point of our example is the ability to
  replace the HTML content directly from the Elixir side and
  for this purpose we added the public `replace(widget, html)`
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
  '''

  defstruct [:module, :pid]

  @doc false
  use GenServer

  require Logger

  alias Kino.JS.Live.Context

  @type t :: %__MODULE__{module: module(), pid: pid()}

  @doc """
  Invoked when the widget server started.

  See `c:GenServer.init/1` for more details.
  """
  @callback init(arg :: term(), ctx :: Context.t()) :: {:ok, ctx :: Context.t()}

  @doc """
  Invoked whenever a new client connects to the server.

  The returned data is passed to the JavaScript `init` function
  of the connecting client.
  """
  @callback handle_connect(ctx :: Context.t()) :: {:ok, data :: term(), ctx :: Context.t()}

  @doc """
  Invoked to handle client events.
  """
  @callback handle_event(event :: String.t(), payload :: term(), ctx :: Context.t()) ::
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
  @callback handle_call(msg :: term(), {pid(), reference()}, ctx :: Context.t()) ::
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
            when reason: :normal | :shutdown | {:shutdown, term()}

  @optional_callbacks init: 2,
                      handle_event: 3,
                      handle_call: 3,
                      handle_cast: 2,
                      handle_info: 2,
                      terminate: 2

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Kino.JS.Live

      import Kino.JS.Live.Context, only: [assign: 2, update: 3, broadcast_event: 3]

      @before_compile Kino.JS.Live
    end
  end

  def __before_compile__(env) do
    unless Module.defines?(env.module, {:__js_info__, 0}) do
      message = """
      make sure to include Kino.JS in #{inspect(env.module)} and define the necessary assets.

          use Kino.JS
          use Kino.JS.Live

      See Kino.JS for more details.
      """

      IO.warn(message, Macro.Env.stacktrace(env))
    end

    nil
  end

  @doc """
  Instantiates a live JavaScript widget defined by `module`.

  The given `init_arg` is passed to the `init/2` callback when
  the underlying widget process is started.
  """
  @spec new(module(), term()) :: t()
  def new(module, init_arg) do
    {:ok, pid} = Kino.start_child({__MODULE__, {module, init_arg}})
    %__MODULE__{module: module, pid: pid}
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Sends an asynchronous request to the widget server.

  See `GenServer.cast/2` for more details.
  """
  @spec cast(t(), term()) :: :ok
  def cast(widget, term) do
    GenServer.cast(widget.pid, term)
  end

  @doc """
  Makes a synchronous call to the widget server and waits
  for its reply.

  See `GenServer.call/3` for more details.
  """
  def call(widget, term, timeout \\ 5_000) do
    GenServer.call(widget.pid, term, timeout)
  end

  @impl true
  def init({module, init_arg}) do
    ctx = Context.new()

    {:ok, ctx} =
      if has_function?(module, :init, 2) do
        module.init(init_arg, ctx)
      else
        {:ok, ctx}
      end

    {:ok, %{module: module, client_pids: [], client_monitor_refs: [], ctx: ctx}}
  end

  @impl true
  def handle_cast(msg, state) do
    unless has_function?(state.module, :handle_cast, 2) do
      raise "attempted to cast #{inspect(__MODULE__)}, but no handle_cast/2 was defined #{inspect(state.module)}"
    end

    {:noreply, ctx} = state.module.handle_cast(msg, state.ctx)
    {:noreply, apply_ctx(state, ctx)}
  end

  @impl true
  def handle_call(msg, from, state) do
    unless has_function?(state.module, :handle_call, 3) do
      raise "attempted to call #{inspect(__MODULE__)}, but no handle_call/3 was defined in #{inspect(state.module)}"
    end

    {:reply, reply, ctx} = state.module.handle_call(msg, from, state.ctx)
    {:reply, reply, apply_ctx(state, ctx)}
  end

  @impl true
  def handle_info({:connect, pid}, state) do
    ref = Process.monitor(pid)

    state = update_in(state.client_pids, &[pid | &1])
    state = update_in(state.client_monitor_refs, &[ref | &1])

    {:ok, data, ctx} = state.module.handle_connect(state.ctx)
    send(pid, {:connect_reply, data})

    {:noreply, apply_ctx(state, ctx)}
  end

  def handle_info({:event, event, payload}, state) do
    unless has_function?(state.module, :handle_event, 3) do
      raise "received #{inspect(event)} event in #{inspect(__MODULE__)}, but no handle_event/3 was defined in #{inspect(state.module)}"
    end

    {:noreply, ctx} = state.module.handle_event(event, payload, state.ctx)
    {:noreply, apply_ctx(state, ctx)}
  end

  def handle_info({:DOWN, ref, :process, pid, _reason} = msg, state) do
    if ref in state.client_monitor_refs do
      state = update_in(state.client_pids, &List.delete(&1, pid))
      state = update_in(state.client_monitor_refs, &List.delete(&1, ref))
      {:noreply, state}
    else
      apply_handle_info(msg, state)
    end
  end

  def handle_info(msg, state) do
    apply_handle_info(msg, state)
  end

  @impl true
  def terminate(reason, state) do
    if has_function?(state.module, :terminate, 2) do
      state.module.terminate(reason, state.ctx)
    end

    :ok
  end

  defp apply_ctx(state, ctx) do
    for {event, payload} <- Enum.reverse(ctx.events),
        pid <- state.client_pids,
        do: send(pid, {:event, event, payload})

    ctx = %{ctx | events: []}
    %{state | ctx: ctx}
  end

  defp apply_handle_info(msg, state) do
    {:noreply, ctx} =
      if has_function?(state.module, :handle_info, 2) do
        state.module.handle_info(msg, state.ctx)
      else
        Logger.error(
          "received message in #{inspect(__MODULE__)}, but no handle_info/2 was defined in #{inspect(state.module)}"
        )

        {:noreply, state.ctx}
      end

    {:noreply, apply_ctx(state, ctx)}
  end

  defp has_function?(module, function, arity) do
    Code.ensure_loaded?(module) and function_exported?(module, function, arity)
  end
end
