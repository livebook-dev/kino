defmodule LiveWidget.VegaLite do
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
        |> LiveWidget.VegaLite.start()
        |> LiveWidget.render()

      for i <- 1..300 do
        point = %{x: i / 10, y: :math.sin(i / 10)}
        LiveWidget.VegaLite.push(vl_widget, point)
        Process.sleep(25)
      end
  """

  # === Communication protocol ===
  #
  # The client should connect to the widget by sending:
  #
  #     {:connect, pid}
  #
  # The widget responds with
  #
  #     {:connect_reply, %{spec: VegaLite.spec}}
  #
  # The widget may then keep sending one of the following events
  #
  #     {:push, %{data: list, dataset: binary, window: non_neg_integer}}

  use GenServer

  @widget_type :vega_lite

  @type state :: %{
          vl: VegaLite.t(),
          window: non_neg_integer(),
          datasets: %{binary() => list()},
          pids: list(pid())
        }

  @doc """
  Starts a widget process with the given VegaLite definition.
  """
  @spec start(VegaLite.t()) :: LiveWidget.t()
  def start(vl) do
    opts = [vl: vl]

    case GenServer.start(__MODULE__, opts) do
      {:ok, pid} ->
        %LiveWidget{pid: pid, type: @widget_type}

      {:error, reason} ->
        raise RuntimeError, "failed to start VegaLite widget server, reason: #{inspect(reason)}"
    end
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
  @spec push(LiveWidget.t(), map(), keyword()) :: :ok
  def push(widget, data_point, opts \\ []) do
    dataset = opts[:dataset]
    window = opts[:window]
    GenServer.cast(widget.pid, {:push, dataset, [data_point], window})
  end

  @doc """
  Appends a number of data points to the graphic dataset.

  See `push/3` for more details.
  """
  @spec push_many(LiveWidget.t(), list(map()), keyword()) :: :ok
  def push_many(widget, data, opts \\ []) do
    dataset = opts[:dataset]
    window = opts[:window]
    GenServer.cast(widget.pid, {:push, dataset, data, window})
  end

  @doc """
  Removes all data points from the graphic dataset.

  ## Options

    * `dataset` - name of the targetted dataset from
      the VegaLite specification. Defaults to the default
      anonymous dataset.
  """
  @spec clear(LiveWidget.t(), keyword()) :: :ok
  def clear(widget, opts \\ []) do
    dataset = opts[:dataset]
    GenServer.cast(widget.pid, {:clear, dataset})
  end

  @impl true
  def init(opts) do
    vl = Keyword.fetch!(opts, :vl)

    {:ok, %{vl: vl, datasets: %{}, pids: []}}
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

  def handle_info({:DOWN, _, :process, pid, _}, state) do
    {:noreply, %{state | pids: List.delete(state.pids, pid)}}
  end
end
