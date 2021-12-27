defmodule Kino.VegaLite do
  @moduledoc """
  A widget wrapping [VegaLite](https://hexdocs.pm/vega_lite) graphic.

  This widget allow for rendering regular VegaLite graphic
  and then streaming new data points to update the graphic.

  ## Examples

      widget =
        Vl.new(width: 400, height: 400)
        |> Vl.mark(:line)
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "y", type: :quantitative)
        |> Kino.VegaLite.new()
        |> Kino.render()

      for i <- 1..300 do
        point = %{x: i / 10, y: :math.sin(i / 10)}
        Kino.VegaLite.push(widget, point)
        Process.sleep(25)
      end
  """

  use Kino.JS, assets_path: "lib/assets/vega_lite"
  use Kino.JS.Live

  @type t :: Kino.JS.Live.t()

  @doc """
  Starts a widget process with the given VegaLite definition.
  """
  @spec new(VegaLite.t()) :: t()
  def new(vl) when is_struct(vl, VegaLite) do
    Kino.JS.Live.new(__MODULE__, vl)
  end

  # TODO: remove in v0.3.0
  @deprecated "Use Kino.VegaLite.new/1 instead"
  def start(vl), do: new(vl)

  @doc false
  @spec static(VegaLite.t()) :: Kino.JS.t()
  def static(vl) when is_struct(vl, VegaLite) do
    data = %{
      spec: VegaLite.to_spec(vl),
      datasets: []
    }

    Kino.JS.new(__MODULE__, data, export_info_string: "vega-lite", export_key: :spec)
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

    Kino.JS.Live.cast(widget, {:push, dataset, [data_point], window})
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

    Kino.JS.Live.cast(widget, {:push, dataset, data_points, window})
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
    Kino.JS.Live.cast(widget, {:clear, dataset})
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
    Kino.JS.Live.cast(widget, {:periodically, interval_ms, acc, fun})
  end

  @impl true
  def init(vl, ctx) do
    {:ok, assign(ctx, vl: vl, datasets: %{})}
  end

  @compile {:no_warn_undefined, {VegaLite, :to_spec, 1}}

  @impl true
  def handle_connect(ctx) do
    data = %{
      spec: VegaLite.to_spec(ctx.assigns.vl),
      datasets: for({dataset, data} <- ctx.assigns.datasets, do: [dataset, data])
    }

    {:ok, data, ctx}
  end

  @impl true
  def handle_cast({:push, dataset, data, window}, ctx) do
    ctx =
      ctx
      |> broadcast_event("push", %{data: data, dataset: dataset, window: window})
      |> update(:datasets, fn datasets ->
        {current_data, datasets} = Map.pop(datasets, dataset, [])

        new_data =
          if window do
            Enum.take(current_data ++ data, -window)
          else
            current_data ++ data
          end

        Map.put(datasets, dataset, new_data)
      end)

    {:noreply, ctx}
  end

  def handle_cast({:clear, dataset}, ctx) do
    ctx =
      ctx
      |> broadcast_event("push", %{data: [], dataset: dataset, window: 0})
      |> update(:datasets, &Map.delete(&1, dataset))

    {:noreply, ctx}
  end

  def handle_cast({:periodically, interval_ms, acc, fun}, state) do
    periodically_iter(interval_ms, acc, fun)
    {:noreply, state}
  end

  @impl true
  def handle_info({:periodically_iter, interval_ms, acc, fun}, ctx) do
    periodically_iter(interval_ms, acc, fun)
    {:noreply, ctx}
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
