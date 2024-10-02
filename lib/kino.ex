defmodule Kino do
  @moduledoc ~S'''
  Client-driven interactive widgets for Livebook.

  Kino is the library used by Livebook to render rich and interactive
  outputs directly from your Elixir code.

  ## Getting started

  Livebook is distributed with a set of interactive tutorials and
  examples, including some that specifically focus on Kino. If you're
  just getting started, going through these is highly recommended.

  You can access these notebooks by starting Livebook and clicking
  on "Learn" in the sidebar.

  ## Built-in kinos

  Kino provides several built-in kinos. The `Kino.Shorts` module
  provides a facade to access and use most of the Kinos in this
  project, although you can also use their modules directly as
  listed in the sidebar.

  For user interactions, `Kino.Input` and `Kino.Control` provide
  a set of widgets for entering data and capturing user events.
  See the respective module documentation for examples.

  Kino also provides facilities to aid debugging, such as
  `Kino.Process` and a custom `dbg()` implementation that integrates
  with Livebook.

  ## Custom kinos

  Kino renders any data structure that implements the `Kino.Render`
  protocol, falling back to the `Kernel.inspect/2` representation
  whenever an implementation is not available. You can customize
  how your own data structures are rendered by implementing the
  `Kino.Render` protocol.

  You can also implement your own kinos by writing custom JavaScript,
  see `Kino.JS` and `Kino.JS.Live` for more details.

  > #### Packaging {: .info}
  >
  > When publishing custom kinos and smart cells, please consider
  > the following guidelines:
  >
  >   * prefix package name with `kino_`, usually followed by the
  >     name of the integration, such as `kino_vega_lite`, `kino_ecto`
  >
  >   * namespace all modules under `KinoExample`, not `Kino.Example`.
  >     Note that official packages maintained by the Livebook team
  >     expose public APIs under `Kino.`, because they are essentially
  >     direct extensions of `Kino` and we make sure no conflicting
  >     modules exist. Unofficial packages should follow the usual
  >     Elixir conventions with respect to module names
  >
  '''

  import Kernel, except: [inspect: 1]

  require Logger

  @type nothing :: :"do not show this result in output"

  @doc """
  Renders the given term as cell output.

  This effectively allows any Livebook cell to have multiple
  evaluation results.
  """
  @spec render(term()) :: term()
  def render(term) do
    output = Kino.Render.to_livebook(term)
    Kino.Bridge.put_output(output)
    term
  end

  @doc """
  Inspects the given term as cell output.

  This works essentially the same as `IO.inspect/2`, except it
  always produces colored text and respects the configuration
  set with `configure/1`.

  Opposite to `render/1`, it does not attempt to render the given
  term as a kino.
  """
  @spec inspect(term(), keyword()) :: term()
  def inspect(term, opts \\ []) do
    label = if label = opts[:label], do: "#{label}: ", else: ""

    output = Kino.Output.inspect(term, opts)
    output = update_in(output.text, &(label <> &1))
    Kino.Bridge.put_output(output)

    term
  end

  @doc """
  Configures Kino.

  The supported options are:

    * `:inspect`

  They are discussed individually in the sections below.

  ## Inspect

  A keyword list containing inspect options used for printing
  usual evaluation results. Defaults to pretty formatting with
  a limit of 50 entries.

  To show more entries, you configure a higher limit:

      Kino.configure(inspect: [limit: 200])

  You can also show all entries by setting the limit to `:infinity`,
  but keep in mind that for large data structures it is memory-expensive
  and is not an advised configuration in this case. Instead prefer
  the use of `IO.inspect/2` with `:infinity` limit when needed.

  See `Inspect.Opts` for the full list of options.
  """
  @spec configure(keyword()) :: :ok
  def configure(options) do
    Kino.Config.configure(options)
  end

  @doc ~S"""
  Renders a kino that periodically calls the given function
  to render a new result.

  The callback receives a stream element and should return a term
  to be rendered.

  This function uses `Kino.Frame` as the underlying kino.
  It returns nothing (a non-printable result).

  ## Examples

  An animation is created by turning a stream of values into
  subsequent animation frames:

      Stream.interval(100)
      |> Stream.take(100)
      |> Kino.animate(fn i ->
        Kino.Markdown.new("**Iteration: `#{i}`**")
      end)

  Alternatively an integer may be passed as a shorthand for
  `Stream.interval/1`:

      # Render new Markdown every 100ms
      Kino.animate(100, fn i ->
        Kino.Markdown.new("**Iteration: `#{i}`**")
      end)
  """
  @spec animate(Enumerable.t() | pos_integer(), (term() -> any())) :: nothing()
  def animate(stream_or_interval_ms, fun) when is_function(fun, 1) do
    animate(stream_or_interval_ms, nil, fn item, nil ->
      {:cont, fun.(item), nil}
    end)
  end

  @doc ~S"""
  A stateful version of `animate/2`.

  The callback receives a stream element and the accumulated state
  and it should return either of:

    * `{:cont, term_to_render, state}` - to continue

    * `:halt` - to no longer schedule callback evaluation

  ## Examples

  This function is primarily useful to consume `Kino.Control` events:

      button = Kino.Control.button("Click")

      button
      |> Kino.Control.stream()
      |> Kino.animate(0, fn _event, counter ->
        new_counter = counter + 1
        md = Kino.Markdown.new("**Clicks: `#{new_counter}`**")
        {:cont, md, new_counter}
      end)
  """
  @spec animate(
          Enumerable.t() | pos_integer(),
          state,
          (term(), state -> {:cont, term(), state} | :halt)
        ) :: nothing()
        when state: term()
  def animate(stream_or_interval_ms, state, fun)

  def animate(interval_ms, state, fun) when is_integer(interval_ms) and is_function(fun, 2) do
    animate(Stream.interval(interval_ms), state, fun)
  end

  def animate(stream, state, fun) when is_function(fun, 2) do
    frame = Kino.Frame.new() |> Kino.render()

    listen(stream, state, fn item, state ->
      case safe_apply(fun, [item, state], "Kino.animate") do
        {:ok, {:cont, term, state}} ->
          Kino.Frame.render(frame, term)
          {:cont, state}

        {:ok, :halt} ->
          :halt

        {:error, _, _} ->
          {:cont, state}
      end
    end)

    nothing()
  end

  @doc ~S"""
  Starts a process that consumes a stream with `fun` without blocking execution.

  It returns the PID of the started process. The process can be terminated
  with `Kino.terminate_child/1`.

  Note that events are processed by `fun` sequentially. If you want
  to process them concurrently, use `async_listen/2`.

  ## Examples

  This function is primarily useful to consume `Kino.Control` events:

      Kino.Control.button("Greet")
      |> Kino.listen(fn event -> IO.inspect(event) end)

  You can also merge multiple controls into a single stream. For example,
  in order to merge them and tag each with a distinct event:

      button = Kino.Control.button("Hello")
      input = Kino.Input.checkbox("Check")

      stream = Kino.Control.tagged_stream([hello: button, check: input])

      Kino.listen(stream, fn
        {:hello, event} -> ...
        {:check, event} -> ...
      end)

  Any other stream works as well:

      Stream.interval(100)
      |> Stream.take(10)
      |> Kino.listen(fn i -> IO.puts("Ping #{i}") end)

  Finally, an integer may be passed as a shorthand for `Stream.interval/1`:

      Kino.listen(100, fn i -> IO.puts("Ping #{i}") end)

  """
  @spec listen(Enumerable.t() | pos_integer(), (term() -> any())) :: pid()
  def listen(stream_or_interval_ms, fun)

  def listen(interval_ms, fun) when is_integer(interval_ms) and is_function(fun, 1) do
    listen(Stream.interval(interval_ms), fun)
  end

  def listen(stream, fun) when is_function(fun, 1) do
    async(fn -> Enum.each(stream, &safe_apply(fun, [&1], "Kino.listen")) end)
  end

  @doc ~S"""
  A stateful version of `listen/2`.

  The callback should return either of:

    * `{:cont, state}` - to continue

    * `:halt` - to stop listening

  ## Examples

      button = Kino.Control.button("Click")

      Kino.listen(button, 0, fn _event, counter ->
        new_counter = counter + 1
        IO.puts("Clicks: #{new_counter}")
        {:cont, new_counter}
      end)

  """
  @spec listen(
          Enumerable.t() | pos_integer(),
          state,
          (term(), state -> {:cont, state} | :halt)
        ) :: pid()
        when state: term()
  def listen(stream_or_interval_ms, state, fun)

  def listen(interval_ms, state, fun) when is_integer(interval_ms) and is_function(fun, 2) do
    listen(Stream.interval(interval_ms), state, fun)
  end

  def listen(stream, state, fun) when is_function(fun, 2) do
    async(fn ->
      Enum.reduce_while(stream, state, fn item, state ->
        case safe_apply(fun, [item, state], "Kino.listen") do
          {:ok, {:cont, state}} -> {:cont, state}
          {:ok, :halt} -> {:halt, state}
          {:error, _, _} -> {:cont, state}
        end
      end)
    end)
  end

  defp safe_apply(fun, args, context) do
    try do
      {:ok, apply(fun, args)}
    catch
      kind, error ->
        Logger.error(
          "#{context} with #{Kernel.inspect(fun)} failed with reason:\n\n" <>
            Exception.format(kind, error, __STACKTRACE__)
        )

        {:error, kind, error}
    end
  end

  defp async(fun) do
    {:ok, pid} =
      Kino.start_child(%{
        id: Task,
        start: {Kino.Terminator, :start_task, [self(), fun]},
        restart: :temporary
      })

    pid
  end

  @doc """
  Same as `listen/2`, except each event is processed concurrently.
  """
  @spec async_listen(Enumerable.t() | pos_integer(), (term() -> any())) :: pid()
  def async_listen(stream_or_interval_ms, fun)

  def async_listen(interval_ms, fun) when is_integer(interval_ms) and is_function(fun, 1) do
    async_listen(Stream.interval(interval_ms), fun)
  end

  def async_listen(stream, fun) when is_function(fun, 1) do
    async(fn ->
      # For organization purposes we start all tasks under a separate
      # supervisor and only that supervisor is started with Kino.start_child/1

      start_fun = fn ->
        {:ok, task_supervisor} = start_child(Task.Supervisor)
        task_supervisor
      end

      reducer = fn event, task_supervisor ->
        {[{event, task_supervisor}], task_supervisor}
      end

      after_fun = fn task_supervisor ->
        for {_, pid, _, _} <- DynamicSupervisor.which_children(task_supervisor),
            is_pid(pid),
            Process.alive?(pid) do
          ref = Process.monitor(pid)

          receive do
            {:DOWN, ^ref, _, _, _} -> :ok
          end
        end

        DynamicSupervisor.terminate_child(Kino.DynamicSupervisor, task_supervisor)
      end

      stream
      |> Stream.transform(start_fun, reducer, after_fun)
      |> Enum.each(fn {event, task_supervisor} ->
        Task.Supervisor.start_child(task_supervisor, fn ->
          safe_apply(fun, [event], "Kino.async_listen")
        end)
      end)
    end)
  end

  @doc """
  Returns a special value that results in no visible output.

  ## Examples

  This is especially handy when you wish to suppress the default output
  of a cell. For instance, a cell containing this would normally result
  in verbose response output:

      resp = Req.get!("https://example.org")

  That output can be suppressed by appending a call to `nothing/0`:

      resp = Req.get!("https://example.org")
      Kino.nothing()
  """
  @spec nothing() :: nothing()
  def nothing() do
    :"do not show this result in output"
  end

  @doc """
  Starts a process under the Kino supervisor.

  The process is automatically terminated when the current process
  terminates or the current cell reevaluates.

  If you want to terminate the started process, use
  `terminate_child/1`. If you terminate the process manually,
  the Kino supervisor might restart it if the child's `:restart`
  strategy says so.

  > #### Nested start {: .warning}
  >
  > It is not possible to use `start_child/1` while initializing
  > another process started this way. In other words, you generally
  > cannot call `start_child/1` inside callbacks such as `c:GenServer.init/1`
  > or `c:Kino.JS.Live.init/2`. If you do that, starting the process
  > will block forever.
  >
  > On creation, many kinos use `start_child/1` underneath, which means
  > that you cannot use functions such as `Kino.DataTable.new/1` in
  > `c:GenServer.init/1`. If you need to do that, you must either
  > create the kinos beforehand and pass in the `GenServer` argument,
  > or create them in `c:GenServer.handle_continue/2`.
  """
  @spec start_child(
          Supervisor.child_spec()
          | {module(), term()}
          | module()
        ) :: DynamicSupervisor.on_start_child()
  def start_child(child_spec) do
    %{start: start} = child_spec = Supervisor.child_spec(child_spec, [])
    parent = self()
    gl = Process.group_leader()
    child_spec = %{child_spec | start: {Kino.Terminator, :start_child, [start, parent, gl]}}
    DynamicSupervisor.start_child(Kino.DynamicSupervisor, child_spec)
  end

  @doc """
  Similar to `start_child/2` but returns the new pid or raises an error.
  """
  @spec start_child!(Supervisor.child_spec() | {module(), term()} | module()) :: pid()
  def start_child!(child_spec) do
    case start_child(child_spec) do
      {:ok, pid} ->
        pid

      {:ok, pid, _info} ->
        pid

      {:error, reason} ->
        raise "failed to start child with the spec #{Kernel.inspect(child_spec)}.\n" <>
                "Reason: #{Exception.format_exit(reason)}"
    end
  end

  @doc """
  Terminates a child started with `start_child/1`.

  Returns `:ok` if the child was found and terminated, or
  `{:error, :not_found}` if the child was not found.
  """
  @doc since: "0.9.1"
  @spec terminate_child(pid()) :: :ok | {:error, :not_found}
  def terminate_child(pid) when is_pid(pid) do
    DynamicSupervisor.terminate_child(Kino.DynamicSupervisor, pid)
  end

  @doc ~S"""
  Interrupts evaluation with the given message.

  This function raises a specific error to let Livebook know that
  evaluation should be stopped. The error message and a `Continue`
  button are shown to the user, who can then attempt to resolve the
  source of the interrupt before resuming execution.

  > #### Do not use interrupt inside listeners {: .warning}
  >
  > Since `interrupt!/2` aborts the execution, it cannot be used
  > inside `Kino.listen/2` or other event listeners. In such cases,
  > you can use `Kino.Frame` and render any messages directly within
  > the frame, using `Kino.Text` or `Kino.Markdown`.

  ## Examples

      text =
        Kino.Input.text("Input")
        |> Kino.render()
        |> Kino.Input.read()

      if text == "" do
        Kino.interrupt!(:error, "Input required")
      end

      # This will not be run if the `interrupt!` is called above
      Kino.Markdown.new("**You entered:** #{text}")
  """
  @spec interrupt!(:normal | :error, String.t()) :: no_return()
  def interrupt!(variant, message) when variant in [:normal, :error] and is_binary(message) do
    raise Kino.InterruptError, variant: variant, message: message
  end

  @doc """
  Returns a temporary directory that gets removed when the runtime
  terminates.
  """
  @spec tmp_dir() :: String.t() | nil
  def tmp_dir() do
    case Kino.Bridge.get_tmp_dir() do
      {:ok, path} -> path
      _ -> nil
    end
  end

  @doc """
  Returns the directories that contain `.beam` files for modules
  defined in the notebook.
  """
  @spec beam_paths() :: list(String.t())
  def beam_paths() do
    case Kino.Bridge.get_beam_paths() do
      {:ok, paths} -> paths
      _ -> []
    end
  end

  @doc """
  Recompiles dependencies.

  Once you have installed dependencies with `Mix.install/1`, this will
  recompile any outdated path dependencies declared during the install.

  > #### Reproducibility {: .warning}
  >
  > Keep in mind that recompiling dependency modules is **not** going
  > to mark any cells as stale. This means that the given notebook
  > state may no longer be reproducible. This function is meant as a
  > utility when prototyping alongside a Mix project.
  """
  @spec recompile() :: :ok
  def recompile() do
    unless Mix.installed?() do
      raise "trying to call Kino.recompile/0, but Mix.install/2 was never called"
    end

    elixir_version = System.version()

    if Version.compare(elixir_version, "1.16.2") == :lt do
      raise "Kino.recompile/0 requires Elixir 1.16.2 or newer to work, but you are using #{elixir_version}"
    end

    IEx.Helpers.recompile()
    :ok
  end
end
