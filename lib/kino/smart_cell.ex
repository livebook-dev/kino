defmodule Kino.SmartCell do
  @moduledoc ~S'''
  An interface for defining custom smart cells.

  A smart cell is a UI wizard designed for producing a piece of code
  that accomplishes a specific task. In other words, a smart cell is
  like a code template parameterized through UI interactions.

  This module builds on top of `Kino.JS.Live`, consequently keeping
  all of its component and communication mechanics. The additional
  callbacks specify how the UI maps to source code.

  ## Usage

  Defining a custom cell is similar to writing a regular `Kino.JS.Live`
  component, with a couple specifics.

  First, we only need to define callbacks, so there is no need for
  using `Kino.JS.Live.new/2`. The `c:Kino.JS.Live.init/2` callback
  always receives `t:attrs/0` as the first argument.

  Second, we add a few new bits, namely `use Kino.SmartCell` and the
  two corresponding callback definitions.

  Here is an outline of a custom module

      defmodule Kino.SmartCell.Custom do
        use Kino.JS
        use Kino.JS.Live
        use Kino.SmartCell, name: "Our custom wizard"

        @impl true
        def init(attrs, ctx) do
          ...
        end

        # Other Kino.JS.Live callbacks
        ...

        @impl true
        def to_attrs(ctx) do
          ...
        end

        @impl true
        def to_source(attrs) do
          ...
        end
      end

  Additionally, in order for Livebook to pick up the custom cell, we
  need to register our module. This usually happens in `application.ex`

      Kino.SmartCell.register(Kino.SmartCell.Custom)

  ## Example

  As a minimal example, that's how we can define a cell that allows
  editing the underlying code directly through a textarea.

      defmodule Kino.SmartCell.Plain do
        use Kino.JS
        use Kino.JS.Live
        use Kino.SmartCell, name: "Plain code editor"

        @impl true
        def init(attrs, ctx) do
          source = attrs["source"] || ""
          {:ok, assign(ctx, source: source)}
        end

        @impl true
        def handle_connect(ctx) do
          {:ok, %{source: ctx.assigns.source}, ctx}
        end

        @impl true
        def handle_event("update", %{"source" => source}, ctx) do
          broadcast_event(ctx, "update", %{"source" => source})
          {:noreply, assign(ctx, source: source)}
        end

        @impl true
        def to_attrs(ctx) do
          %{"source" => ctx.assigns.source}
        end

        @impl true
        def to_source(attrs) do
          attrs["source"]
        end

        asset "main.js" do
          """
          export function init(ctx, payload) {
            ctx.importCSS("main.css");

            ctx.root.innerHTML = `
              <textarea id="source"></textarea>
            `;

            const textarea = ctx.root.querySelector("#source");
            textarea.value = payload.source;

            textarea.addEventListener("blur", (event) => {
              ctx.pushEvent("update", { source: event.target.value });
            });

            ctx.handleEvent("update", ({ source }) => {
              textarea.value = source;
            });
          }
          """
        end

        asset "main.css" do
          """
          #source {
            box-sizing: border-box;
            width: 100%;
            min-height: 100px;
          }
          """
        end
      end

  And then we would register it as

      Kino.SmartCell.register(Kino.SmartCell.Plain)
  '''

  require Logger

  import Kino.Utils, only: [has_function?: 3]

  alias Kino.JS.Live.Context

  @typedoc """
  Attributes are an intermediate form of smart cell state, used to
  persist and restore cells.

  Attributes are computed using `c:to_attrs/1` and used to generate
  the source code using `c:to_source/1`.

  Note that attributes are serialized and deserialized as JSON for
  persistence, hence make sure to use JSON-friendly data structures.

  Persisted attributes are passed to `c:Kino.JS.Live.init/2` as the
  first argument and should be used to restore the relevant state.
  """
  @type attrs :: map()

  @doc """
  Invoked to compute the smart cell state as serializable attributes.
  """
  @callback to_attrs(ctx :: Context.t()) :: attrs()

  @doc """
  Invoked to generate source code based on the given attributes.
  """
  @callback to_source(attrs()) :: String.t()

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Kino.SmartCell

      @smart_opts opts

      @before_compile Kino.SmartCell
    end
  end

  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :smart_opts)

    name = Keyword.fetch!(opts, :name)

    quote do
      def child_spec(%{ref: ref, attrs: attrs, target_pid: target_pid}) do
        %{
          id: __MODULE__,
          start: {Kino.SmartCell.Server, :start_link, [__MODULE__, ref, attrs, target_pid]},
          restart: :temporary
        }
      end

      def __smart_definition__() do
        %{
          kind: Atom.to_string(__MODULE__),
          module: __MODULE__,
          name: unquote(name)
        }
      end
    end
  end

  @doc """
  Returns a list of available smart cell definitions.
  """
  def definitions() do
    for module <- get_modules(), do: module.__smart_definition__()
  end

  @doc """
  Registers a new smart cell.

  This should usually be called in `application.ex` when starting
  the application.

  ## Examples

      Kino.SmartCell.register(Kino.SmartCell.Custom)
  """
  @spec register(module()) :: :ok
  def register(module) do
    unless has_function?(module, :__smart_definition__, 0) do
      raise ArgumentError, "module #{inspect(module)} does not define a smart cell"
    end

    modules = get_modules()
    updated_modules = if module in modules, do: modules, else: modules ++ [module]
    put_modules(updated_modules)
  end

  @registry_key :smart_cell_modules

  defp get_modules() do
    Application.get_env(:kino, @registry_key, [])
  end

  defp put_modules(modules) do
    Application.put_env(:kino, @registry_key, modules)
  end
end
