defmodule Kino.Screen do
  @moduledoc ~S"""
  Provides a LiveView like experience for building forms in Livebook.

  Each screen must implement the `c:init/1` and `c:render/1` callbacks.
  Event handlers can be attached by calling the `control/2` function.

  Each user on the page get their own version of their screen, which
  is not shared. If you want to share them, you can pass a frame as
  argument to the screen, as shown in the "Dynamic select" example below.

  ## Dynamic select

  Here is an example that allows you to render different forms depending
  on the value of a select, each form triggering a different action:

      defmodule MyScreen do
        @behaviour Kino.Screen

        # Import Kino.Control for forms, Kino.Input for inputs, and Screen for control/2
        import Kino.{Control, Input, Screen}

        # A form to search by name...
        def render(%{selection: :name} = state) do
          form(
            [name: text("Name")],
            submit: "Search"
          )
          |> control(&by_name/2)
          |> add_layout(state)
        end

        # A form to search by address...
        def render(%{selection: :address} = state) do
          form(
            [address: text("Address")],
            submit: "Search"
          )
          |> control(&by_address/2)
          |> add_layout(state)
        end

        # The general layout of the scren
        defp add_layout(element, state) do
          select =
            select("Search by", [name: "Name", address: "Address"], default: state.selection)
            |> control(&selection/2)

          Kino.Layout.grid([select, element, state.frame])
        end

        ## Events handlers

        defp selection(%{value: selection}, state) do
          %{state | selection: selection}
        end

        defp by_name(%{data: %{name: name}}, state) do
          Kino.Frame.render(state.frame, "SEARCHING BY NAME: #{name}")
          state
        end

        defp by_address(%{data: %{address: address}}, state) do
          Kino.Frame.render(state.frame, "SEARCHING BY ADDRESS: #{address}")
          state
        end
      end

      # In the state, we track the current selection and the frame to print results to
      state = %{selection: :name, frame: Kino.Frame.new()}
      Kino.Screen.new(MyScreen, state)

  ## Wizard like

  Here is an example of how to build wizard like functionality with `Kino.Screen`:

      defmodule MyScreen do
        @behaviour Kino.Screen

        # Import Kino.Control for forms, Kino.Input for inputs, and Screen for control/2
        import Kino.{Control, Input, Screen}

        # The first screen gets the name.
        #
        # The `control/2` function comes from `Kino.Screen` and it specifies
        # which function to be invoked on form submission.
        def render(%{page: 1} = state) do
          form(
            [name: text("Name", default: state.name)],
            submit: "Step one"
          )
          |> control(&step_one/2)
          |> add_layout(state)
        end

        # The next screen gets the address.
        #
        # We also call `add_go_back/1` to add a back button.
        def render(%{page: 2} = state) do
          form(
            [address: text("Address", default: state.address)],
            submit: "Step two"
          )
          |> control(&step_two/2)
          |> add_layout(state)
        end

        # The final screen shows a success message.
        def render(%{page: 3} = state) do
          Kino.Text.new("Well done, #{state.name}. You live in #{state.address}.")
          |> add_layout(state)
        end

        # This is the layout shared across all pages.
        defp add_layout(element, state) do
          prefix = if state.error do
            Kino.Text.new("Error: #{state.error}!")
          end

          suffix = if state.page > 1 do
            button("Go back")
            |> control(&go_back/2)
          end

          [prefix, element, suffix]
          |> Enum.reject(&is_nil/1)
          |> Kino.Layout.grid()
        end

        ## Events handlers

        defp step_one(%{data: %{name: name}}, state) do
          if name == "" do
            %{state | name: name, error: "name can't be blank"}
          else
            %{state | name: name, error: nil, page: 2}
          end
        end

        defp step_two(%{data: %{address: address}}, state) do
          if address == "" do
            %{state | address: address, error: "address can't be blank"}
          else
            %{state | address: address, error: nil, page: 3}
          end
        end

        defp go_back(_, state) do
          %{state | page: state.page - 1}
        end
      end

      # Our screen will guide the user to provide its name and address.
      # We also have a field keeping the current page and if there is an error.
      state = %{page: 1, name: nil, address: nil, error: nil}
      Kino.Screen.new(MyScreen, state)
  """

  defmodule Server do
    @moduledoc false

    use GenServer

    def start_link(mod_frame_state) do
      GenServer.start_link(__MODULE__, mod_frame_state)
    end

    @impl true
    def init({module, frame, fun, event, state}) do
      {:ok, render(module, frame, event.origin, fun.(event, state))}
    end

    @impl true
    def handle_info({{Kino.Screen, fun}, data}, {module, frame, client_id, state}) do
      state = fun.(data, state)
      {:noreply, render(module, frame, client_id, state)}
    end

    defp render(module, frame, client_id, state) do
      Kino.Frame.render(frame, module.render(state), to: client_id)
      {module, frame, client_id, state}
    end
  end

  defmodule Watcher do
    @moduledoc false
    use GenServer

    def start_link(mod_frame_state) do
      GenServer.start_link(__MODULE__, {mod_frame_state, self()})
    end

    @impl true
    def init({{module, frame, state}, parent}) do
      Kino.Frame.render(frame, module.render(state))

      data = %{
        module: module,
        frame: frame,
        state: state,
        sup: parent,
        children: %{}
      }

      {:ok, data, {:continue, {:init, parent}}}
    end

    @impl true
    def handle_continue({:init, parent}, state) do
      [_, {_id, sup, _, _}] = Supervisor.which_children(parent)
      {:noreply, %{state | sup: sup}}
    end

    @impl true
    def handle_info({{Kino.Screen, fun}, event}, data) do
      if not Map.has_key?(event, :origin) do
        raise "expected control/2 to map to an event with origin"
      end

      %{module: module, frame: frame, state: state, sup: sup, children: children} = data

      children =
        case DynamicSupervisor.start_child(sup, {Server, {module, frame, fun, event, state}}) do
          {:ok, pid} -> Map.put(children, event.origin, pid)
          {:error, _} -> children
        end

      {:noreply, %{data | children: children}}
    end

    def handle_info({:client_leave, client_id}, %{sup: sup, children: children} = data) do
      {pid, children} = Map.pop(children, client_id)
      pid && DynamicSupervisor.terminate_child(sup, pid)
      {:noreply, %{data | children: children}}
    end
  end

  @typedoc "The state of the screen"
  @type state :: term()

  @doc """
  Callback invoked to render the screen, whenever there
  is a control event.

  It receives the state and it must return a renderable
  output.

  The first time this function is called, it is done within
  a temporary process until the user first interacts with
  an element via `control/2`. Then all events happen in a
  user-specific process.
  """
  @callback render(state) :: term()

  @doc """
  Receives a control or an input and invokes the given 2-arity function
  once its actions are triggered.
  """
  @spec control(element, (map(), state() -> state())) :: element
        when element: Kino.Control.t() | Kino.Input.t()

  def control(from, fun) when is_function(fun, 2) do
    Kino.Control.subscribe(from, {__MODULE__, fun})
    from
  end

  def new(module, state) when is_atom(module) do
    frame = Kino.Frame.new()

    children = [
      # If they boot, we always restart them in case of errors
      {DynamicSupervisor, max_restarts: 1_000_000, max_seconds: 1},
      {Watcher, {module, frame, state}}
    ]

    opts = [strategy: :one_for_one]

    {:ok, _pid} =
      Kino.start_child(%{
        id: __MODULE__,
        start: {Supervisor, :start_link, [children, opts]},
        type: :supervisor
      })

    frame
  end
end
