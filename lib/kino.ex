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

  `Kino.Markdown` wraps Markdown content for richer text rendering.

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
  Returns a kino that periodically calls the given function
  to render a new result.

  The callback is run every `interval_ms` milliseconds and receives
  the accumulated value. The callback should return either of:

    * `{:cont, term_to_render, acc}` - the continue

    * `:halt` - to no longer schedule callback evaluation

  This function uses `Kino.Frame` as the underlying kino.

  ## Examples

      # Render new Markdown every 100ms
      Kino.animate(100, 0, fn i ->
        md = Kino.Markdown.new("**Iteration: `#{i}`**")
        {:cont, md, i + 1}
      end)
  """
  @spec animate(
          pos_integer(),
          term(),
          (term() -> {:cont, term(), acc :: term()} | :halt)
        ) :: nothing()
  def animate(interval_ms, acc, fun) do
    frame = Kino.Frame.new()

    Kino.Frame.periodically(frame, interval_ms, acc, fn acc ->
      case fun.(acc) do
        {:cont, term, acc} ->
          Kino.Frame.render(frame, term)
          {:cont, acc}

        :halt ->
          :halt
      end
    end)

    Kino.render(frame)

    nothing()
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
  """
  @spec start_child(
          Supervisor.child_spec()
          | {module(), term()}
          | module()
        ) :: DynamicSupervisor.on_start_child()
  def start_child(child_spec) do
    # Starting a process that calls Kino.start_child/1 in its init
    # would block forever, so we don't allow nesting
    if Kino.DynamicSupervisor in Process.get(:"$ancestors", []) do
      raise ArgumentError,
            "could not start #{Kernel.inspect(child_spec)} using Kino.start_child/1," <>
              " because the current process has been started with Kino.start_child/1." <>
              " Please move the nested start outside and pass the result as an argument to this process"
    end

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
        Kino.Bridge.monitor_object(pid, Kino.Terminator.cross_node_name(), {:terminate, pid})
      end

      resp
    after
      Process.group_leader(self(), initial_gl)
    end
  end
end
