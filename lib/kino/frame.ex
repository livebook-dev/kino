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
          client_pids: list(pid()),
          output: Kino.Output.t() | nil
        }

  @doc """
  Starts a widget process.
  """
  @spec new() :: t()
  def new() do
    {:ok, pid} = Kino.start_child(__MODULE__)
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
  def init(_opts) do
    {:ok, %{client_pids: [], output: nil}}
  end

  @impl true
  def handle_cast({:render, term}, state) do
    output = Kino.Render.to_livebook(term)

    for pid <- state.client_pids do
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

    {:noreply, %{state | client_pids: [pid | state.client_pids]}}
  end

  def handle_info({:periodically_iter, interval_ms, acc, fun}, state) do
    periodically_iter(interval_ms, acc, fun)
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, %{state | client_pids: List.delete(state.client_pids, pid)}}
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
