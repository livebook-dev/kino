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
          | text_inline()
          | text_block()
          | markdown()
          | image()
          | js_static()
          | js_dynamic()
          | table_dynamic()
          | frame_dynamic()
          | input()
          | control()

  @typedoc """
  An empty output that should be ignored whenever encountered.
  """
  @type ignored :: :ignored

  @typedoc """
  Regular text, adjacent such outputs can be treated as a whole.
  """
  @type text_inline :: binary()

  @typedoc """
  Standalone text block.
  """
  @type text_block :: {:text, binary()}

  @typedoc """
  Markdown content.
  """
  @type markdown :: {:markdown, binary()}

  @typedoc """
  A raw image in the given format.
  """
  @type image :: {:image, content :: binary(), mime_type :: binary()}

  @typedoc """
  JavaScript powered output with static data.

  When rendered, the specified JS is invoked with the given data
  and can freely manipulate document tree in the output element.

  See `Kino.JS` for more details.
  """
  @type js_static() :: {:js_static, info :: js_info(), data :: term()}

  @typedoc """
  JavaScript powered output with dynamic data and events.

  This output points to a server process that serves data requests
  and sends custom events.

  ## Communication protocol

  A client process should connect to the server process by sending:

      {:connect, pid(), info :: %{origin: term()}}

  And expect the following reply:

      {:connect_reply, initial_data}

  The server process may then keep sending one of the following events:

      {:event, event :: String.t(), payload :: term()}

  The client process may keep sending one of the following events:

      {:event, event :: String.t(), payload :: term(), info :: %{origin: term()}}

  See `Kino.JS` and `Kino.JS.Live` for more details.
  """
  @type js_dynamic() :: {:js_dynamic, info :: js_info(), pid()}

  @typedoc """
  Data describing a custom JS output component.

  ## Assets

  The `:assets` map includes information about the relevant files.

    * `:archive_path` - an absolute path to a `.tar.gz` archive
      with all the assets

    * `:hash` - a checksum of all assets in the archive

    * `:js_path` - a relative asset path pointing to the JavaScript
      entrypoint module
  """
  @type js_info() :: %{
          assets: %{
            archive_path: String.t(),
            hash: String.t(),
            js_path: String.t()
          }
        }

  @typedoc """
  Interactive data table.

  This output points to a server process that serves data requests,
  handling filtering, sorting and slicing data as necessary.

  ## Communication protocol

  A client process should connect to the server process by sending:

      {:connect, pid()}

  And expect the following reply:

      @type column :: %{
        key: term(),
        label: binary()
      }

      {:connect_reply, %{
        name: binary(),
        columns: list(column()),
        features: list(:refetch | :pagination | :sorting)
      }}

  The client may then query for table rows by sending the following requests:

      @type rows_spec :: %{
        offset: non_neg_integer(),
        limit: pos_integer(),
        order_by: nil | term(),
        order: :asc | :desc,
      }

      {:get_rows, pid(), rows_spec()}

  To which the server responds with retrieved data:

      @type row :: %{
        # An identifier, opaque to the client
        ref: term(),
        # A string value for every column key
        fields: list(%{term() => binary()})
      }

      {:rows, %{
        rows: list(row()),
        total_rows: non_neg_integer(),
        # Possibly an updated columns specification
        columns: :initial | list(column())
      }}
  """
  @type table_dynamic :: {:table_dynamic, pid()}

  @typedoc """
  Animable output.

  This output points to a server process that clients can talk to.

  ## Communication protocol

  A client process should connect to the server process by sending:

      {:connect, pid()}

  And expect the following reply:

      {:connect_reply, %{output: Kino.Output.t() | nil}}

  The server process may then keep sending one of the following events:

      {:render, %{output: Kino.Output.t()}}
  """
  @type frame_dynamic :: {:frame_dynamic, pid()}

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

  @type input_ref :: reference()
  @type input_id :: String.t()

  @type input_attrs ::
          %{
            type: :text,
            ref: input_ref(),
            id: input_id(),
            label: String.t(),
            default: String.t(),
            destination: Process.dest()
          }
          | %{
              type: :textarea,
              ref: input_ref(),
              id: input_id(),
              label: String.t(),
              default: String.t(),
              destination: Process.dest()
            }
          | %{
              type: :password,
              ref: input_ref(),
              id: input_id(),
              label: String.t(),
              default: String.t(),
              destination: Process.dest()
            }
          | %{
              type: :number,
              ref: input_ref(),
              id: input_id(),
              label: String.t(),
              default: number() | nil,
              destination: Process.dest()
            }
          | %{
              type: :url,
              ref: input_ref(),
              id: input_id(),
              label: String.t(),
              default: String.t() | nil,
              destination: Process.dest()
            }
          | %{
              type: :select,
              ref: input_ref(),
              id: input_id(),
              label: String.t(),
              default: term(),
              destination: Process.dest(),
              options: list({value :: term(), label :: String.t()})
            }
          | %{
              type: :checkbox,
              ref: input_ref(),
              id: input_id(),
              label: String.t(),
              default: boolean(),
              destination: Process.dest()
            }
          | %{
              type: :range,
              ref: input_ref(),
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
              ref: input_ref(),
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

  @type control_ref :: reference()

  @type control_attrs ::
          %{
            type: :keyboard,
            ref: control_ref(),
            destination: Process.dest(),
            events: list(:keyup | :keydown | :status)
          }
          | %{
              type: :button,
              ref: control_ref(),
              destination: Process.dest(),
              label: String.t()
            }
          | %{
              type: :form,
              ref: control_ref(),
              destination: Process.dest(),
              fields: list({field :: atom(), input_attrs()}),
              submit: String.t() | nil,
              # Currently we always use true, but we can support
              # other tracking modes in the future
              report_changes: %{(field :: atom()) => true},
              reset_on_submit: list(field :: atom())
            }

  @doc """
  See `t:text_inline/0`.
  """
  @spec text_inline(binary()) :: t()
  def text_inline(text) when is_binary(text) do
    text
  end

  @doc """
  See `t:text_block/0`.
  """
  @spec text_block(binary()) :: t()
  def text_block(text) when is_binary(text) do
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
  See `t:js_static/0`.
  """
  @spec js_static(js_info(), term()) :: t()
  def js_static(info, data) when is_map(info) do
    {:js_static, info, data}
  end

  @doc """
  See `t:js_dynamic/0`.
  """
  @spec js_dynamic(js_info(), pid()) :: t()
  def js_dynamic(info, pid) when is_map(info) and is_pid(pid) do
    {:js_dynamic, info, pid}
  end

  @doc """
  See `t:table_dynamic/0`.
  """
  @spec table_dynamic(pid()) :: t()
  def table_dynamic(pid) when is_pid(pid) do
    {:table_dynamic, pid}
  end

  @doc """
  See `t:frame_dynamic/0`.
  """
  @spec frame_dynamic(pid()) :: t()
  def frame_dynamic(pid) when is_pid(pid) do
    {:frame_dynamic, pid}
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
  Returns `t:text_block/0` with the inspected term.
  """
  @spec inspect(term(), keyword()) :: t()
  def inspect(term, opts \\ []) do
    inspected = Kernel.inspect(term, inspect_opts(opts))
    text_block(inspected)
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
end
