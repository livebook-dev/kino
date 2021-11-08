defmodule Kino.Frame do
  @moduledoc """
  A widget wrapping a static output.

  This widget serves as a placeholder for a regular output,
  so that it can be dynamically replaced at any time.

  Also see `Kino.animate/3` which offers a convenience on
  top of this widget.

  ## Examples

      widget = Kino.Frame.new() |> tap(&Kino.render/1)

      for i <- 1..100 do
        Kino.Frame.render(widget, i)
        Process.sleep(50)
      end

  Or with a scheduled task in the background.

      widget = Kino.Frame.new() |> tap(&Kino.render/1)

      Kino.Frame.periodically(widget, 50, 0, fn i ->
        Kino.Frame.render(widget, i)
        {:cont, i + 1}
      end)
  """

  @doc false
  use GenServer, restart: :temporary

  defstruct [:pid]

  @type t :: %__MODULE__{pid: pid()}

  @typedoc false
  @type state :: %{
          parent_monitor_ref: reference(),
          pids: list(pid()),
          output: Kino.Output.t() | nil
        }

  @doc """
  Starts a widget process.
  """
  @spec new() :: t()
  def new() do
    parent = self()
    opts = [parent: parent]

    {:ok, pid} = DynamicSupervisor.start_child(Kino.WidgetSupervisor, {__MODULE__, opts})

    %__MODULE__{pid: pid}
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Renders the given term within the frame.

  This works similarly to `Kino.render/1`, but the frame
  widget only shows the last rendered result.
  """
  @spec render(t(), term()) :: :ok
  def render(widget, term) do
    GenServer.cast(widget.pid, {:render, term})
  end

  @doc """
  Registers a callback to run periodically in the widget process.

  The callback is run every `interval_ms` milliseconds and receives
  the accumulated value. The callback should return either of:

    * `{:cont, acc}` - the continue with the new accumulated value

    * `:halt` - to no longer schedule callback evaluation

  The callback is run for the first time immediately upon registration.
  """
  @spec periodically(t(), pos_integer(), term(), (term() -> {:cont, term()} | :halt)) :: :ok
  def periodically(widget, interval_ms, acc, fun) do
    GenServer.cast(widget.pid, {:periodically, interval_ms, acc, fun})
  end

  @impl true
  def init(opts) do
    parent = Keyword.fetch!(opts, :parent)

    parent_monitor_ref = Process.monitor(parent)

    {:ok, %{parent_monitor_ref: parent_monitor_ref, pids: [], output: nil}}
  end

  @impl true
  def handle_cast({:render, term}, state) do
    output = Kino.Render.to_livebook(term)

    for pid <- state.pids do
      send(pid, {:render, %{output: output}})
    end

    state = %{state | output: output}

    {:noreply, state}
  end

  def handle_cast({:periodically, interval_ms, acc, fun}, state) do
    periodically_iter(interval_ms, acc, fun)
    {:noreply, state}
  end

  @impl true
  def handle_info({:connect, pid}, state) do
    Process.monitor(pid)

    send(pid, {:connect_reply, %{output: state.output}})

    {:noreply, %{state | pids: [pid | state.pids]}}
  end

  def handle_info({:periodically_iter, interval_ms, acc, fun}, state) do
    periodically_iter(interval_ms, acc, fun)
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _object, _reason}, %{parent_monitor_ref: ref} = state) do
    {:stop, :shutdown, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, %{state | pids: List.delete(state.pids, pid)}}
  end

  defp periodically_iter(interval_ms, acc, fun) do
    case fun.(acc) do
      {:cont, acc} ->
        Process.send_after(self(), {:periodically_iter, interval_ms, acc, fun}, interval_ms)

      :halt ->
        :ok
    end
  end
end
