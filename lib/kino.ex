defmodule Kino do
  @moduledoc ~S'''
  Client-driven interactive widgets for Livebook.

  Kino is the library used by Livebook to render rich and interactive
  outputs directly from your Elixir code.

  ## Built-in kinos

  Kino renders any data structure that implements the `Kino.Render`
  protocol, falling back to the `Kernel.inspect/2` representation
  whenever an implementation is not available. The data structures
  supported by Kino out of the box are:

  ### Kino.DataTable

  `Kino.DataTable` implements a data table output for user-provided
  tabular data:

      data = [
        %{id: 1, name: "Elixir", website: "https://elixir-lang.org"},
        %{id: 2, name: "Erlang", website: "https://www.erlang.org"}
      ]

      Kino.DataTable.new(data)

  ### Kino.ETS

  `Kino.ETS` implements a data table output for ETS tables in the
  system:

      tid = :ets.new(:users, [:set, :public])
      Kino.ETS.new(tid)

  ### Kino.Image

  `Kino.Image` wraps binary image content and can be used to render
  raw images of any given format:

      content = File.read!("/path/to/image.jpeg")
      Kino.Image.new(content, "image/jpeg")

  ### Kino.Markdown

  `Kino.Markdown` renders Markdown content, in case you need richer text:

      Kino.Markdown.new("""
      # Example

      A regular Markdown file.

      ## Code

      ```elixir
      "Elixir" |> String.graphemes() |> Enum.frequencies()
      ```

      ## Table

      | ID | Name   | Website                 |
      | -- | ------ | ----------------------- |
      | 1  | Elixir | https://elixir-lang.org |
      | 2  | Erlang | https://www.erlang.org  |
      """)

  ### Kino.Mermaid

  `Kino.Mermaid` renders Mermaid graphs:

      Kino.Mermaid.new("""
      graph TD;
        A-->B;
        A-->C;
        B-->D;
        C-->D;
      """)

  ### Kino.Frame

  `Kino.Frame` is a placeholder for static outputs that can
  be dynamically updated.

      frame = Kino.Frame.new() |> Kino.render()

      for i <- 1..100 do
        Kino.Frame.render(frame, i)
        Process.sleep(50)
      end

  Also see `Kino.animate/3`.

  ### User interactions

  `Kino.Input` and `Kino.Control` provide a set of widgets for
  entering data and capturing user events. See the respective
  module documentation for examples.

  ### All others

  All other data structures are rendered as text using Elixir's
  `Kernel.inspect/2`.

  ## Custom kinos

  Kino makes it possible to define custom JavaScript powered
  kinos, see `Kino.JS` and `Kino.JS.Live` for more details.
  '''

  import Kernel, except: [inspect: 1]

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

    {:text, text} = Kino.Output.inspect(term, opts)
    output = {:text, label <> text}
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

    * `{:cont, term_to_render, state}` - the continue

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

  def animate(interval_ms, state, fun) when is_integer(interval_ms) do
    frame = Kino.Frame.new()

    fun =
      cond do
        is_function(fun, 1) ->
          # TODO: remove on Kino v0.8
          IO.warn(
            "Passing arity-1 function to Kino.animate/3 is deprecated, " <>
              "please use Kino.animate/2 or pass an arity-2 function"
          )

          fn _i, state -> fun.(state) end

        is_function(fun, 2) ->
          fun
      end

    Kino.Frame.periodically(frame, interval_ms, {0, state}, fn {i, state} ->
      case fun.(i, state) do
        {:cont, term, state} ->
          Kino.Frame.render(frame, term)
          {:cont, {i + 1, state}}

        :halt ->
          :halt
      end
    end)

    Kino.render(frame)

    nothing()
  end

  def animate(stream, state, fun) when is_function(fun, 2) do
    frame = Kino.Frame.new() |> Kino.render()

    listen(stream, state, fn item, state ->
      case fun.(item, state) do
        {:cont, term, state} ->
          Kino.Frame.render(frame, term)
          {:cont, state}

        :halt ->
          :halt
      end
    end)

    nothing()
  end

  @doc ~S"""
  Asynchronously consumes a stream with `fun`.

  ## Examples

  This function is primarily useful to consume `Kino.Control` events:

      button = Kino.Control.button("Greet")

      button
      |> Kino.Control.stream()
      |> Kino.listen(fn event -> IO.inspect(event) end)

  Or in the tagged version:

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
  @spec listen(Enumerable.t() | pos_integer(), (term() -> any())) :: :ok
  def listen(stream_or_interval_ms, fun)

  def listen(interval_ms, fun) when is_integer(interval_ms) and is_function(fun, 1) do
    listen(Stream.interval(interval_ms), fun)
  end

  def listen(stream, fun) when is_function(fun, 1) do
    async(fn -> Enum.each(stream, fun) end)
  end

  @doc ~S"""
  A stateful version of `listen/2`.

  The callback should return either of:

    * `{:cont, state}` - the continue

    * `:halt` - to stop listening

  ## Examples

      button = Kino.Control.button("Click")

      button
      |> Kino.Control.stream()
      |> Kino.listen(0, fn _event, counter ->
        new_counter = counter + 1
        IO.puts("Clicks: #{new_counter}")
        {:cont, new_counter}
      end)

  """
  @spec listen(
          Enumerable.t() | pos_integer(),
          state,
          (term(), state -> {:cont, state} | :halt)
        ) :: :ok
        when state: term()
  def listen(stream_or_interval_ms, state, fun)

  def listen(interval_ms, state, fun) when is_integer(interval_ms) and is_function(fun, 2) do
    listen(Stream.interval(interval_ms), state, fun)
  end

  def listen(stream, state, fun) when is_function(fun, 2) do
    async(fn ->
      Enum.reduce_while(stream, state, fn item, state ->
        case fun.(item, state) do
          {:cont, state} -> {:cont, state}
          :halt -> {:halt, state}
        end
      end)
    end)
  end

  defp async(fun) do
    Kino.start_child({Task, fun})
    :ok
  end

  @doc """
  Returns a special value that results in no visible output.
  """
  @spec nothing() :: nothing()
  def nothing() do
    :"do not show this result in output"
  end

  @doc """
  Starts a process under the Kino supervisor.

  The process is automatically terminated when the current process
  terminates or the current cell reevaluates.

  > #### Nested start {: .warning}
  >
  > It is not possible to use `start_child/1` while initializing
  > another process started this way. In other words, you generally
  > cannot call `start_child/1` inside callbacks such as `c:GenServer.init/1`
  > or `c:Kino.JS.Live.init/2`. If you do that, starting the process
  > will block forever.
  >
  > Note that creating many kinos uses `start_child/1` underneath,
  > hence the same restriction applies to starting those. See
  > `c:Kino.JS.Live.init/2` for more details.
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
    child_spec = %{child_spec | start: {Kino, :__start_override__, [start, parent, gl]}}
    DynamicSupervisor.start_child(Kino.DynamicSupervisor, child_spec)
  end

  @doc false
  def __start_override__({mod, fun, args}, parent, gl) do
    # We switch the group leader, so that the newly started
    # process gets the same group leader as the caller
    initial_gl = Process.group_leader()

    Process.group_leader(self(), gl)

    try do
      {resp, pid} =
        case apply(mod, fun, args) do
          {:ok, pid} = resp -> {resp, pid}
          {:ok, pid, _info} = resp -> {resp, pid}
          resp -> {resp, nil}
        end

      if pid do
        Kino.Bridge.reference_object(pid, parent)

        Kino.Bridge.monitor_object(pid, Kino.Terminator.cross_node_name(), {:terminate, pid},
          ack?: true
        )
      end

      resp
    after
      Process.group_leader(self(), initial_gl)
    end
  end
end
