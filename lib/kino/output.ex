defmodule Kino.Output do
  @moduledoc """
  A number of output formats supported by Livebook.
  """

  import Kernel, except: [inspect: 2]

  @typedoc """
  Livebook cell output may be one of these values and gets rendered accordingly.
  """
  @type t ::
          ignored()
          | stdout()
          | text()
          | markdown()
          | image()
          | js()
          | frame()
          | tabs()
          | grid()
          | input()
          | control()

  @typedoc """
  An empty output that should be ignored whenever encountered.
  """
  @type ignored :: :ignored

  @typedoc """
  IO text output, adjacent such outputs are treated as a whole
  """
  @type stdout :: {:stdout, binary()}

  @typedoc """
  Standalone text block.
  """
  @type text :: {:text, binary()}

  @typedoc """
  Markdown content.
  """
  @type markdown :: {:markdown, binary()}

  @typedoc """
  A raw image in the given format.
  """
  @type image :: {:image, content :: binary(), mime_type :: binary()}

  @typedoc """
  JavaScript powered output with dynamic data and events.

  See `Kino.JS` and `Kino.JS.Live` for more details.
  """
  @type js() :: {:js, info :: js_info()}

  @typedoc """
  Data describing a JS output.

  ## Export

  The `:export` map describes how the output should be persisted.
  The output data is put in a Markdown fenced code block.

    * `:info_string` - used as the info string for the Markdown
      code block

    * `:key` - in case the data is a map and only a specific part
      should be exported
  """
  @type js_info :: %{
          js_view: js_view(),
          export:
            nil
            | %{
                info_string: String.t(),
                key: nil | term()
              }
        }

  @typedoc """
  A JavaScript view definition.

  JS view is a component rendered on the client side and possibly
  interacting with a server process within the runtime.

    * `:ref` - unique identifier

    * `:pid` - the server process holding the data and handling
      interactions

  ## Assets

  The `:assets` map includes information about the relevant files.

    * `:archive_path` - an absolute path to a `.tar.gz` archive with
      all the assets

    * `:hash` - a checksum of all assets in the archive

    * `:js_path` - a relative asset path pointing to the JavaScript
      entrypoint module

  ## Communication protocol

  A client process should connect to the server process by sending:

      {:connect, pid(), info :: %{ref: ref(), origin: term()}}

  And expect the following reply:

      {:connect_reply, payload, info :: %{ref: ref()}}

  The server process may then keep sending one of the following events:

      {:event, event :: String.t(), payload, info :: %{ref: ref()}}

  The client process may keep sending one of the following events:

      {:event, event :: String.t(), payload, info :: %{ref: ref(), origin: term()}}

  The client can also send a ping message:

      {:ping, pid(), metadata :: term(), info :: %{ref: ref()}}

  And the server should respond with:

      {:pong, metadata :: term(), info :: %{ref: ref()}}
  """
  @type js_view :: %{
          ref: ref(),
          pid: Process.dest(),
          assets: %{
            archive_path: String.t(),
            hash: String.t(),
            js_path: String.t()
          }
        }

  @typedoc """
  Outputs placeholder.

  Frame with type `:default` includes the initial list of outputs.
  Other types can be used to update outputs within the given frame.

  In all cases the outputs order is reversed, that is, most recent
  outputs are at the top of the stack.
  """
  @type frame :: {:frame, outputs :: list(t()), frame_info()}

  @type frame_info :: %{
          ref: frame_ref(),
          type: :default | :replace | :append
        }

  @type frame_ref :: String.t()

  @typedoc """
  Multiple outputs arranged into tabs.
  """
  @type tabs :: {:tabs, outputs :: list(t()), tabs_info()}

  @type tabs_info :: %{
          labels: list(String.t())
        }

  @typedoc """
  Multiple outputs arranged in a grid.
  """
  @type grid :: {:grid, outputs :: list(t()), grid_info()}

  @type grid_info :: %{
          columns: pos_integer(),
          boxed: boolean()
        }

  @typedoc """
  An input field.

  All inputs have the following properties:

    * `:type` - one of the recognised input types

    * `:ref` - a unique identifier

    * `:id` - a persistent input identifier, the same on every reevaluation

    * `:label` - an arbitrary text used as the input caption

    * `:default` - the initial input value

    * `:destination` - the process to send event messages to

  On top of that, each input type may have additional attributes.
  """
  @type input :: {:input, attrs :: input_attrs()}

  @type input_id :: String.t()

  @type input_attrs ::
          %{
            type: :text,
            ref: ref(),
            id: input_id(),
            label: String.t(),
            default: String.t(),
            destination: Process.dest()
          }
          | %{
              type: :textarea,
              ref: ref(),
              id: input_id(),
              label: String.t(),
              default: String.t(),
              destination: Process.dest()
            }
          | %{
              type: :password,
              ref: ref(),
              id: input_id(),
              label: String.t(),
              default: String.t(),
              destination: Process.dest()
            }
          | %{
              type: :number,
              ref: ref(),
              id: input_id(),
              label: String.t(),
              default: number() | nil,
              destination: Process.dest()
            }
          | %{
              type: :url,
              ref: ref(),
              id: input_id(),
              label: String.t(),
              default: String.t() | nil,
              destination: Process.dest()
            }
          | %{
              type: :select,
              ref: ref(),
              id: input_id(),
              label: String.t(),
              default: term(),
              destination: Process.dest(),
              options: list({value :: term(), label :: String.t()})
            }
          | %{
              type: :checkbox,
              ref: ref(),
              id: input_id(),
              label: String.t(),
              default: boolean(),
              destination: Process.dest()
            }
          | %{
              type: :range,
              ref: ref(),
              id: input_id(),
              label: String.t(),
              default: number(),
              destination: Process.dest(),
              min: number(),
              max: number(),
              step: number()
            }
          | %{
              type: :color,
              ref: ref(),
              id: input_id(),
              label: String.t(),
              default: String.t(),
              destination: Process.dest()
            }

  @typedoc """
  A control widget.

  All controls have the following properties:

    * `:type` - one of the recognised control types

    * `:ref` - a unique identifier

    * `:destination` - the process to send event messages to

  On top of that, each control type may have additional attributes.

  ## Events

  All control events are sent to `:destination` as `{:event, id, info}`,
  where info is a map including additional details. In particular, it
  always includes `:origin`, which is an opaque identifier of the client
  that triggered the event.
  """
  @type control :: {:control, attrs :: control_attrs()}

  @type control_attrs ::
          %{
            type: :keyboard,
            ref: ref(),
            destination: Process.dest(),
            events: list(:keyup | :keydown | :status)
          }
          | %{
              type: :button,
              ref: ref(),
              destination: Process.dest(),
              label: String.t()
            }
          | %{
              type: :form,
              ref: ref(),
              destination: Process.dest(),
              fields: list({field :: atom(), input_attrs()}),
              submit: String.t() | nil,
              # Currently we always use true, but we can support
              # other tracking modes in the future
              report_changes: %{(field :: atom()) => true},
              reset_on_submit: list(field :: atom())
            }

  @type ref :: String.t()

  @doc """
  See `t:text/0`.
  """
  @spec text(binary()) :: t()
  def text(text) when is_binary(text) do
    {:text, text}
  end

  @doc """
  See `t:markdown/0`.
  """
  @spec markdown(binary()) :: t()
  def markdown(content) when is_binary(content) do
    {:markdown, content}
  end

  @doc """
  See `t:image/0`.
  """
  @spec image(binary(), binary()) :: t()
  def image(content, mime_type) when is_binary(content) and is_binary(mime_type) do
    {:image, content, mime_type}
  end

  @doc """
  See `t:js/0`.
  """
  @spec js(js_info()) :: t()
  def js(info) when is_map(info) do
    {:js, info}
  end

  @doc """
  See `t:frame/0`.
  """
  @spec frame(list(t()), frame_info()) :: t()
  def frame(outputs, info) when is_list(outputs) and is_map(info) do
    {:frame, outputs, info}
  end

  @doc """
  See `t:tabs/0`.
  """
  @spec tabs(list(t()), tabs_info()) :: t()
  def tabs(outputs, info) when is_list(outputs) and is_map(info) do
    {:tabs, outputs, info}
  end

  @doc """
  See `t:grid/0`.
  """
  @spec grid(list(t()), grid_info()) :: t()
  def grid(outputs, info) when is_list(outputs) and is_map(info) do
    {:grid, outputs, info}
  end

  @doc """
  See `t:input/0`.
  """
  @spec input(input_attrs()) :: t()
  def input(attrs) when is_map(attrs) do
    {:input, attrs}
  end

  @doc """
  See `t:control/0`.
  """
  @spec control(control_attrs()) :: t()
  def control(attrs) when is_map(attrs) do
    {:control, attrs}
  end

  @doc """
  Returns `t:text/0` with the inspected term.
  """
  @spec inspect(term(), keyword()) :: t()
  def inspect(term, opts \\ []) do
    inspected = Kernel.inspect(term, inspect_opts(opts))
    text(inspected)
  end

  defp inspect_opts(opts) do
    default_opts = [pretty: true, width: 100, syntax_colors: syntax_colors()]
    config_opts = Kino.Config.configuration(:inspect, [])

    default_opts
    |> Keyword.merge(config_opts)
    |> Keyword.merge(opts)
  end

  defp syntax_colors() do
    [
      atom: :blue,
      boolean: :magenta,
      number: :blue,
      nil: :magenta,
      regex: :red,
      string: :green,
      reset: :reset
    ]
  end

  @doc """
  Generates a random binary identifier.
  """
  @spec random_ref() :: ref()
  def random_ref() do
    :crypto.strong_rand_bytes(20) |> Base.encode32(case: :lower)
  end
end
