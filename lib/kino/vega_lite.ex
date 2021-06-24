defmodule Kino.VegaLite do
  @moduledoc """
  A widget wrapping [VegaLite](https://hexdocs.pm/vega_lite) graphic.

  This widget allow for rendering regular VegaLite graphic
  and then streaming new data points to update the graphic.

  ## Examples

      vl_widget =
        Vl.new(width: 400, height: 400)
        |> Vl.mark(:line)
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)
        |> Kino.VegaLite.new()
        |> Kino.render()

      for i <- 1..300 do
        point = %{x: i / 10, y: :math.sin(i / 10)}
        Kino.VegaLite.push(vl_widget, point)
        Process.sleep(25)
      end
  """

  use GenServer, restart: :temporary

  defstruct [:pid]

  @type t :: %__MODULE__{pid: pid()}

  @typedoc false
  @type state :: %{
          parent_monitor_ref: reference(),
          vl: VegaLite.t(),
          window: non_neg_integer(),
          datasets: %{binary() => list()},
          pids: list(pid())
        }

  @doc """
  Starts a widget process with the given VegaLite definition.
  """
  @spec new(VegaLite.t()) :: t()
  def new(vl) when is_struct(vl, VegaLite) do
    parent = self()
    opts = [vl: vl, parent: parent]

    {:ok, pid} = DynamicSupervisor.start_child(Kino.WidgetSupervisor, {__MODULE__, opts})

    %__MODULE__{pid: pid}
  end

  # TODO: remove in v0.3.0
  @deprecated "Use Kino.VegaLite.new/1 instead"
  def start(vl), do: new(vl)

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Appends a single data point to the graphic dataset.

  ## Options

    * `:window` - the maximum number of data points to keep.
      This option is useful when you are appending new
      data points to the plot over a long period of time.

    * `dataset` - name of the targetted dataset from
      the VegaLite specification. Defaults to the default
      anonymous dataset.
  """
  @spec push(t(), map(), keyword()) :: :ok
  def push(widget, data_point, opts \\ []) do
    dataset = opts[:dataset]
    window = opts[:window]

    data_point = Map.new(data_point)

    GenServer.cast(widget.pid, {:push, dataset, [data_point], window})
  end

  @doc """
  Appends a number of data points to the graphic dataset.

  See `push/3` for more details.
  """
  @spec push_many(t(), list(map()), keyword()) :: :ok
  def push_many(widget, data_points, opts \\ []) when is_list(data_points) do
    dataset = opts[:dataset]
    window = opts[:window]

    data_points = Enum.map(data_points, &Map.new/1)

    GenServer.cast(widget.pid, {:push, dataset, data_points, window})
  end

  @doc """
  Removes all data points from the graphic dataset.

  ## Options

    * `dataset` - name of the targetted dataset from
      the VegaLite specification. Defaults to the default
      anonymous dataset.
  """
  @spec clear(t(), keyword()) :: :ok
  def clear(widget, opts \\ []) do
    dataset = opts[:dataset]
    GenServer.cast(widget.pid, {:clear, dataset})
  end

  @doc """
  Registers a callback to run periodically in the widget process.

  The callback is run every `interval_ms` milliseconds and recives
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
    vl = Keyword.fetch!(opts, :vl)
    parent = Keyword.fetch!(opts, :parent)

    parent_monitor_ref = Process.monitor(parent)

    {:ok, %{parent_monitor_ref: parent_monitor_ref, vl: vl, datasets: %{}, pids: []}}
  end

  @impl true
  def handle_cast({:push, dataset, data, window}, state) do
    for pid <- state.pids do
      send(pid, {:push, %{data: data, dataset: dataset, window: window}})
    end

    state =
      update_in(state.datasets[dataset], fn current_data ->
        current_data = current_data || []

        if window do
          Enum.take(current_data ++ data, -window)
        else
          current_data ++ data
        end
      end)

    {:noreply, state}
  end

  def handle_cast({:clear, dataset}, state) do
    for pid <- state.pids do
      send(pid, {:push, %{data: [], dataset: dataset, window: 0}})
    end

    {_, state} = pop_in(state.datasets[dataset])

    {:noreply, state}
  end

  def handle_cast({:periodically, interval_ms, acc, fun}, state) do
    periodically_iter(interval_ms, acc, fun)
    {:noreply, state}
  end

  @compile {:no_warn_undefined, {VegaLite, :to_spec, 1}}

  @impl true
  def handle_info({:connect, pid}, state) do
    Process.monitor(pid)

    send(pid, {:connect_reply, %{spec: VegaLite.to_spec(state.vl)}})

    for {dataset, data} <- state.datasets do
      send(pid, {:push, %{data: data, dataset: dataset, window: nil}})
    end

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
