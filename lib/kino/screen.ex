defmodule Kino.Screen do
  @moduledoc ~S'''
  Provides a LiveView-like experience for building forms in Livebook.

  The screen receives its initial state and must implement the `c:render/1`
  callback. Event handlers can be attached by calling the `control/2` function.
  The first render of the screen is shared across all users and then further
  interactions happen within a per-user process.

  ## Dynamic form/select

  Here is an example that allows you to build a dynamic form that renders
  values depending on the chosen options. On submit, you then process the
  data (with optional validation) and writes the result into a separate frame.
  The output frame could also be configured to share results across all users.

      defmodule MyScreen do
        @behaviour Kino.Screen

        # Import Kino.Control for forms, Kino.Input for inputs, and Screen for control/2
        import Kino.{Control, Input, Screen}

        @countries [nil: "", usa: "United States", canada: "Canada"]

        @languages [
          usa: [nil: "", en: "English", es: "Spanish"],
          canada: [nil: "", en: "English", fr: "French"]
        ]

        @defaults %{
          country: nil,
          language: nil
        }

        # This is a function we will use to start the screen.
        #
        # Our screen will be placed in a grid with one additional
        # frame to render results into. And the state of the screen
        # holds the form data and the result frame itself.
        def new do
          result_frame = Kino.Frame.new()
          state = %{data: @defaults, frame: result_frame}

          Kino.Layout.grid([
            Kino.Screen.new(__MODULE__, state),
            result_frame
          ])
        end

        def render(%{data: data}) do
          form(
            [
              country: country_select(data),
              language: language_select(data)
            ],
            report_changes: true,
            submit: "Submit"
          )
          |> control(&handle_event/2)
        end

        defp country_select(data) do
          select("Country", @countries, default: data.country)
        end

        defp language_select(data) do
          if languages = @languages[data.country] do
            default = if languages[data.language], do: data.language
            select("Language", languages, default: default)
          end
        end

        def handle_event(%{data: data, type: :change}, state) do
          %{state | data: data}
        end

        def handle_event(%{data: data, type: :submit, origin: client}, state) do
          # If you want to validate the data, you could do
          # here and render a different message.
          markdown =
            Kino.Markdown.new("""
            Submitted!
            * **Country**: #{data.country}
            * **Language**: #{data.language}
            """)

          # We render the results only for the user who submits it,
          # but you can share it across all by removing to: client.
          Kino.Frame.render(state.frame, markdown, to: client)

          # Reset form values on submission
          %{state | data: @defaults}
        end
      end

      MyScreen.new()

  ## Wizard example

  Here is an example of how to build wizard-like functionality with `Kino.Screen`:

      defmodule MyScreen do
        @behaviour Kino.Screen

        # Import Kino.Control for forms, Kino.Input for inputs, and Screen for control/2
        import Kino.{Control, Input, Screen}

        # Our screen will guide the user to provide its name and address.
        # We also have a field keeping the current page and if there is an error.
        def new do
          state = %{page: 1, name: nil, address: nil, error: nil}
          Kino.Screen.new(__MODULE__, state)
        end

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

      MyScreen.new()
  '''

  require Logger

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

    def handle_info(msg, data) do
      Logger.warning("unhandled message by #{inspect(__MODULE__)}: #{inspect(msg)}")
      {:noreply, data}
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
    def init(mod_frame_state_parent) do
      Kino.Bridge.monitor_clients(self())
      {:ok, mod_frame_state_parent, {:continue, :init}}
    end

    @impl true
    def handle_continue(:init, {{module, frame, state}, parent}) do
      [_, {DynamicSupervisor, sup, _, _}] = Supervisor.which_children(parent)
      Kino.Frame.render(frame, module.render(state))

      data = %{
        module: module,
        frame: frame,
        state: state,
        sup: sup,
        children: %{}
      }

      {:noreply, data}
    end

    @impl true
    def handle_info({{Kino.Screen, fun}, event}, data) do
      if not Map.has_key?(event, :origin) do
        raise "expected control/2 to map to an event with origin"
      end

      %{module: module, frame: frame, state: state, sup: sup, children: children} = data

      children =
        case DynamicSupervisor.start_child(sup, {Server, {module, frame, fun, event, state}}) do
          {:ok, pid} ->
            Map.put(children, event.origin, pid)

          {:error, error} ->
            Logger.error(Exception.format_exit(error))
            children
        end

      {:noreply, %{data | children: children}}
    end

    def handle_info({:client_leave, client_id}, %{sup: sup, children: children} = data) do
      {pid, children} = Map.pop(children, client_id)
      pid && DynamicSupervisor.terminate_child(sup, pid)
      {:noreply, %{data | children: children}}
    end

    def handle_info({:client_join, _}, data) do
      {:noreply, data}
    end

    def handle_info(msg, data) do
      Logger.warning("unhandled message by #{inspect(__MODULE__)}: #{inspect(msg)}")
      {:noreply, data}
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

  @doc """
  Creates a new screen with the given module and state.
  """
  @spec new(module(), term()) :: Kino.Frame.t()
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
