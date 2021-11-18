defmodule Kino.Controls do
  @moduledoc """
  A widget for user interactions.

  This widget consists of a number of UI controls that the user
  interacts with, consequenty producing an event stream.

  This widget is often useful paired with `Kino.Frame` for
  presenting content that changes upon user interactions.

  ## Examples

  Create the widget with the desired set of controls.

      widget = Kino.Controls.new([
        %{type: :keyboard, events: [:keyup, :keydown]},
        %{type: :button, event: :hello, label: "Hello"}
      ])

  Next, to receive events from those controls, a process just
  needs to subscribe to the widget.

      Kino.Controls.subscribe(widget)

  As the user interacts with the controls, the subscribed
  process receives corresponding events.

      IEx.Helpers.flush()
      #=> {:control_event, %{origin: #PID<10895.7340.0>, type: :hello}}
      #=> {:control_event, %{key: "o", origin: #PID<10895.7340.0>, type: :keydown}}
      #=> {:control_event, %{key: "o", origin: #PID<10895.7340.0>, type: :keyup}}
      #=> {:control_event, %{key: "k", origin: #PID<10895.7340.0>, type: :keydown}}
      #=> {:control_event, %{key: "k", origin: #PID<10895.7340.0>, type: :keyup}}
      #=> {:control_event, %{origin: #PID<10895.7501.0>, type: :client_join}}
      #=> {:control_event, %{origin: #PID<10895.7501.0>, type: :client_leave}}

  ## Events

  As shown above, the events are delivered in a `{:control_event, event}` tuple.
  Every event includes the following properties:

    * `:type` - the event type, depending on the control either a predefiend such
      as `:keydown` or a custm one

    * `:origin` - a term that identifies the event source, different sources imply
      different clients interacting with the controls

  Specific events may include additional properties on top of that.

  ### Keyboard events

  Keyboard events have `:type` set to either `:keydown` or `:keyup`.

    * `:key` - the value matching the browser [KeyboardEvent.key](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key)

  ### Button events

  Button events have custom `:type`, as specified in the control.

  ### Client events

  Client events have `:type` set to either `:client_join` or `:client_leave` and
  their `:origin` matches the origin in the specific events.
  """

  @doc false
  use GenServer, restart: :temporary

  defstruct [:pid]

  @type t :: %__MODULE__{pid: pid()}

  @typedoc false
  @type state :: %{
          parent_monitor_ref: reference(),
          controls: list(control()),
          client_pids: list(pid()),
          subscriber_pids: list(pid())
        }

  @type control :: keyboard_control() | button_control()
  @type keyboard_control :: %{type: :keyboard, events: list(:keyup | :keydown)}
  @type button_control :: %{type: :button, event: atom(), label: String.t()}

  @doc """
  Starts a widget process with the given controls.
  """
  @spec new(list(control())) :: t()
  def new(controls) do
    validate_controls!(controls)

    parent = self()
    opts = [parent: parent, controls: controls]

    {:ok, pid} = DynamicSupervisor.start_child(Kino.WidgetSupervisor, {__MODULE__, opts})

    %__MODULE__{pid: pid}
  end

  defp validate_controls!(controls) do
    for control <- controls do
      unless valid_control?(control) do
        raise ArgumentError, "invalid control specification: #{inspect(control)}"
      end
    end

    if Enum.count(controls, &(&1.type == :keyboard)) > 1 do
      raise ArgumentError, "controls may include only one :keyboard item"
    end
  end

  defp valid_control?(%{type: :keyboard, events: events}) do
    is_list(events) and events != [] and Enum.all?(events, &(&1 in [:keyup, :keydown]))
  end

  defp valid_control?(%{type: :button, event: event, label: label}) do
    is_atom(event) and is_binary(label)
  end

  defp valid_control?(_), do: false

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Subscribes to control events.
  """
  @spec subscribe(t()) :: :ok
  def subscribe(widget) do
    GenServer.cast(widget.pid, {:subscribe, self()})
  end

  @doc """
  Unsubscribes from control events.
  """
  @spec unsubscribe(t()) :: :ok
  def unsubscribe(widget) do
    GenServer.cast(widget.pid, {:unsubscribe, self()})
  end

  @impl true
  def init(opts) do
    parent = Keyword.fetch!(opts, :parent)
    controls = Keyword.fetch!(opts, :controls)

    parent_monitor_ref = Process.monitor(parent)

    {:ok,
     %{
       parent_monitor_ref: parent_monitor_ref,
       controls: controls,
       client_pids: [],
       subscriber_pids: []
     }}
  end

  @impl true
  def handle_cast({:subscribe, pid}, state) do
    {:noreply, add_subscriber(state, pid)}
  end

  def handle_cast({:unsubscribe, pid}, state) do
    {:noreply, remove_subscriber(state, pid)}
  end

  @impl true
  def handle_info({:connect, pid}, state) do
    Process.monitor(pid)

    send(pid, {:connect_reply, %{controls: state.controls}})

    {:noreply, handle_client_join(state, pid)}
  end

  def handle_info({:event, event}, state) do
    broadcast_event(state, event)

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _object, _reason}, %{parent_monitor_ref: ref} = state) do
    {:stop, :shutdown, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state =
      cond do
        pid in state.client_pids -> handle_client_leave(state, pid)
        pid in state.subscriber_pids -> remove_subscriber(state, pid)
        true -> state
      end

    {:noreply, state}
  end

  defp add_subscriber(state, pid) do
    update_in(state.subscriber_pids, fn pids ->
      if pid in pids, do: pids, else: [pid | pids]
    end)
  end

  defp remove_subscriber(state, pid) do
    update_in(state.subscriber_pids, &List.delete(&1, pid))
  end

  defp handle_client_join(state, pid) do
    event = %{type: :client_join, origin: pid}
    broadcast_event(state, event)

    %{state | client_pids: [pid | state.client_pids]}
  end

  defp handle_client_leave(state, pid) do
    event = %{type: :client_leave, origin: pid}
    broadcast_event(state, event)

    %{state | client_pids: List.delete(state.client_pids, pid)}
  end

  defp broadcast_event(state, event) do
    for pid <- state.subscriber_pids do
      send(pid, {:control_event, event})
    end
  end
end
