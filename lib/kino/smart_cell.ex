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

            textarea.addEventListener("change", (event) => {
              ctx.pushEvent("update", { source: event.target.value });
            });

            ctx.handleEvent("update", ({ source }) => {
              textarea.value = source;
            });

            ctx.handleSync(() => {
              // Synchronously invokes change listeners
              document.activeElement &&
                document.activeElement.dispatchEvent(new Event("change"));
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

  Note that we register a synchronization handler on the client with
  `ctx.handleSync(() => ...)`. This optional handler is invoked before
  evaluation and it should flush any deferred UI changes to the server.
  In our example we listen to textarea's "change" event, which is only
  triggered on blur, so on synchronization we trigger it programmatically.

  ## Collaborative editor

  If a smart cell requires editing some code (like SQL), it may use
  a dedicated editor instance managed by Livebook. The editor handles
  syntax highlighting and collaborative editing, similarly to the
  built-in cells.

  To enable the editor, we need to include `:editor` configuration in
  options returned from the `c:Kino.JS.Live.init/2` callback.

      @impl true
      def init(attrs, ctx) do
        # ...
        {:ok, ctx, editor: [attribute: "code", language: "elixir"]}
      end

  ### Options

    * `:attribute` - the key to put the source text under in `attrs`.
      Required

    * `:language` - the editor language, used for syntax highlighting.
      Defaults to `nil`

    * `:placement` - editor placement within the smart cell, either
      `:top` or `:bottom`. Defaults to `:bottom`

    * `:default_source` - the initial editor source. Defaults to `""`

  ## Other options

  Other than the editor configuration, the following options are
  supported:

    * `:reevaluate_on_change` - if the cell should be reevaluated
      whenever the generated source code changes. This option may be
      helpful in cases where the cell output is a crucial element of
      the UI interactions. Defaults to `false`
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

  @doc """
  Invoked whenever the base evaluation context changes.

  This callback receives the binding and environment available to the
  smart cell code.

  Note that this callback runs asynchronously and it receives the PID
  of the smart cell server, so the result needs to be sent explicitly
  and handled using `c:Kino.JS.Live.handle_info/2`.

  **Important:** remember that data sent between processes is copied,
  so avoid sending large data structures. In particular, when looking
  at variables, instead of sending their values, extract and send
  only the relevant metadata.

  **Important:** avoid any heavy work in this callback, as it runs in
  the same process that evaluates code, so we don't want to block it.
  """
  @callback scan_binding(server :: pid(), Code.binding(), Macro.Env.t()) :: any()

  @doc """
  Invoked when the smart cell code is evaluated.

  This callback receives the result of an evaluation, either the
  return value or an exception if raised.

  This callback runs asynchronously and has the same characteristics
  as `c:scan_binding/3`.
  """
  @callback scan_eval_result(server :: pid(), eval_result()) :: any()

  @type eval_result ::
          {:ok, result :: any()}
          | {:error, Exception.kind(), error :: any(), Exception.stacktrace()}

  @optional_callbacks scan_binding: 3, scan_eval_result: 2

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

  @doc """
  Generates unique variable names with the given prefix.

  When `var_name` is `nil`, allocates and returns the next available
  name. Otherwise, marks the given suffix as taken, provided that
  `var_name` has the given prefix.

  This function can be used to generate default variable names during
  smart cell initialization, so that don't overlap.
  """
  @spec prefixed_var_name(String.t(), String.t() | nil) :: String.t()
  def prefixed_var_name(prefix, var_name)

  def prefixed_var_name(prefix, nil) do
    case Kino.Counter.next(var_counter_key(prefix)) do
      1 -> prefix
      n -> "#{prefix}#{n}"
    end
  end

  def prefixed_var_name(prefix, var_name) do
    with {:ok, suffix} <- parse_var_prefix(var_name, prefix),
         {:ok, n} <- parse_var_suffix(suffix) do
      Kino.Counter.put_max(var_counter_key(prefix), n)
    end

    var_name
  end

  defp parse_var_prefix(string, prefix) do
    if String.starts_with?(string, prefix) do
      {:ok, String.replace_prefix(string, prefix, "")}
    else
      :error
    end
  end

  defp parse_var_suffix(""), do: {:ok, 1}

  defp parse_var_suffix(other) do
    case Integer.parse(other) do
      {n, ""} when n > 1 -> {:ok, n}
      _ -> :error
    end
  end

  defp var_counter_key(prefix), do: {:smart_cell_variable, prefix}

  @doc """
  Checks if the given string is a valid Elixir variable name.
  """
  @spec valid_variable_name?(String.t()) :: boolean()
  def valid_variable_name?(string) when is_binary(string) do
    atom = String.to_atom(string)
    macro_classify_atom(atom) == :identifier
  end

  @doc """
  Converts the given AST to formatted code string.
  """
  @spec quoted_to_string(Macro.t()) :: String.t()
  def quoted_to_string(quoted) do
    quoted
    |> Code.quoted_to_algebra()
    |> Inspect.Algebra.format(90)
    |> IO.iodata_to_binary()
  end

  # ---

  # TODO: use Macro.classify_atom/1 on Elixir 1.14

  defp macro_classify_atom(atom) do
    case macro_inner_classify(atom) do
      :alias -> :alias
      :identifier -> :identifier
      type when type in [:unquoted_operator, :not_callable] -> :unquoted
      _ -> :quoted
    end
  end

  defp macro_inner_classify(atom) when is_atom(atom) do
    cond do
      atom in [:%, :%{}, :{}, :<<>>, :..., :.., :., :"..//", :->] ->
        :not_callable

      atom in [:"::"] ->
        :quoted_operator

      Macro.operator?(atom, 1) or Macro.operator?(atom, 2) ->
        :unquoted_operator

      true ->
        charlist = Atom.to_charlist(atom)

        if macro_valid_alias?(charlist) do
          :alias
        else
          case :elixir_config.identifier_tokenizer().tokenize(charlist) do
            {kind, _acc, [], _, _, special} ->
              if kind == :identifier and not :lists.member(?@, special) do
                :identifier
              else
                :not_callable
              end

            _ ->
              :other
          end
        end
    end
  end

  defp macro_valid_alias?(~c"Elixir" ++ rest), do: macro_valid_alias_piece?(rest)
  defp macro_valid_alias?(_other), do: false

  defp macro_valid_alias_piece?([?., char | rest]) when char >= ?A and char <= ?Z,
    do: macro_valid_alias_piece?(macro_trim_leading_while_valid_identifier(rest))

  defp macro_valid_alias_piece?([]), do: true
  defp macro_valid_alias_piece?(_other), do: false

  defp macro_trim_leading_while_valid_identifier([char | rest])
       when char >= ?a and char <= ?z
       when char >= ?A and char <= ?Z
       when char >= ?0 and char <= ?9
       when char == ?_ do
    macro_trim_leading_while_valid_identifier(rest)
  end

  defp macro_trim_leading_while_valid_identifier(other) do
    other
  end
end
