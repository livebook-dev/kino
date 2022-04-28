defmodule Kino.Frame do
  @moduledoc """
  A placeholder for outputs.

  A frame wraps outputs that can be dynamically updated at
  any time.

  Also see `Kino.animate/3` which offers a convenience on
  top of this kino.

  ## Examples

      frame = Kino.Frame.new() |> Kino.render()

      for i <- 1..100 do
        Kino.Frame.render(frame, i)
        Process.sleep(50)
      end

  Or with a scheduled task in the background.

      frame = Kino.Frame.new() |> Kino.render()

      Kino.Frame.periodically(frame, 50, 0, fn i ->
        Kino.Frame.render(frame, i)
        {:cont, i + 1}
      end)
  """

  @doc false
  use GenServer, restart: :temporary

  defstruct [:ref, :pid]

  @opaque t :: %__MODULE__{ref: String.t(), pid: pid()}

  @typedoc false
  @type state :: %{outputs: list(Kino.Output.t())}

  @doc """
  Creates a new frame.
  """
  @spec new() :: t()
  def new() do
    ref = System.unique_integer() |> Integer.to_string()
    {:ok, pid} = Kino.start_child({__MODULE__, ref})
    %__MODULE__{ref: ref, pid: pid}
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Renders the given term within the frame.

  This works similarly to `Kino.render/1`, but the rendered
  output replaces existing frame contents.
  """
  @spec render(t(), term()) :: :ok
  def render(frame, term) do
    GenServer.cast(frame.pid, {:render, term})
  end

  @doc """
  Renders and appends the given term to the frame.
  """
  @spec append(t(), term()) :: :ok
  def append(frame, term) do
    GenServer.cast(frame.pid, {:append, term})
  end

  @doc """
  Removes all outputs within the given frame.
  """
  @spec clear(t()) :: :ok
  def clear(frame) do
    GenServer.cast(frame.pid, :clear)
  end

  @doc """
  Registers a callback to run periodically in the frame process.

  The callback is run every `interval_ms` milliseconds and receives
  the accumulated value. The callback should return either of:

    * `{:cont, acc}` - the continue with the new accumulated value

    * `:halt` - to no longer schedule callback evaluation

  The callback is run for the first time immediately upon registration.
  """
  @spec periodically(t(), pos_integer(), term(), (term() -> {:cont, term()} | :halt)) :: :ok
  def periodically(frame, interval_ms, acc, fun) do
    GenServer.cast(frame.pid, {:periodically, interval_ms, acc, fun})
  end

  @doc false
  @spec get_outputs(t()) :: list(Kino.Output.t())
  def get_outputs(frame) do
    GenServer.call(frame.pid, :get_outputs)
  end

  @impl true
  def init(ref) do
    {:ok, %{ref: ref, outputs: []}}
  end

  @impl true
  def handle_cast({:render, term}, state) do
    output = Kino.Render.to_livebook(term)
    put_update(state.ref, [output], :replace)
    state = %{state | outputs: [output]}
    {:noreply, state}
  end

  def handle_cast({:append, term}, state) do
    output = Kino.Render.to_livebook(term)
    put_update(state.ref, [output], :append)
    state = %{state | outputs: [output | state.outputs]}
    {:noreply, state}
  end

  def handle_cast(:clear, state) do
    put_update(state.ref, [], :replace)
    state = %{state | outputs: []}
    {:noreply, state}
  end

  def handle_cast({:periodically, interval_ms, acc, fun}, state) do
    periodically_iter(interval_ms, acc, fun)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_outputs, _from, state) do
    {:reply, state.outputs, state}
  end

  @impl true
  def handle_info({:periodically_iter, interval_ms, acc, fun}, state) do
    periodically_iter(interval_ms, acc, fun)
    {:noreply, state}
  end

  defp periodically_iter(interval_ms, acc, fun) do
    case fun.(acc) do
      {:cont, acc} ->
        Process.send_after(self(), {:periodically_iter, interval_ms, acc, fun}, interval_ms)

      :halt ->
        :ok
    end
  end

  defp put_update(ref, outputs, type) do
    output = Kino.Output.frame(outputs, %{ref: ref, type: type})
    Kino.Bridge.put_output(output)
  end
end
