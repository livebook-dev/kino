defmodule Kino.Output do
  @moduledoc """
  A number of output formats supported by Livebook.
  """

  @typedoc """
  Livebook cell output may be one of these values and gets rendered accordingly.
  """
  @type t ::
          ignored()
          | text_inline()
          | text_block()
          | vega_lite_static()
          | vega_lite_dynamic()

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
  [Vega-Lite](https://vega.github.io/vega-lite) graphic.

  `spec` should be a valid Vega-Lite specification, essentially
  JSON represented with Elixir data structures.
  """
  @type vega_lite_static() :: {:vega_lite_static, spec :: map()}

  @typedoc """
  Interactive [Vega-Lite](https://vega.github.io/vega-lite) graphic
  with data streaming capabilities.

  There should be a server process responsible for communication
  with subscribers.

  ## Communication protocol

  A client process should connect to the server process by sending:

      {:connect, pid}

  And expect the following reply:

      {:connect_reply, %{spec: map()}}

  The server process may then keep sending one of the following events:

      {:push, %{data: list(), dataset: binary(), window: non_neg_integer()}}
  """
  @type vega_lite_dynamic :: {:vega_lite_dynamic, pid()}

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
  See `t:vega_lite_static/0`.
  """
  @spec vega_lite_static(vega_lite_spec :: map()) :: t()
  def vega_lite_static(spec) when is_map(spec) do
    {:vega_lite_static, spec}
  end

  @doc """
  See `t:vega_lite_dynamic/0`.
  """
  @spec vega_lite_dynamic(pid()) :: t()
  def vega_lite_dynamic(pid) when is_pid(pid) do
    {:vega_lite_dynamic, pid}
  end

  @doc """
  Returns `t:text_block/0` with the inspectd term.
  """
  @spec inspect(term()) :: t()
  def inspect(term) do
    inspected = inspect(term, inspect_opts())
    text_block(inspected)
  end

  defp inspect_opts(opts \\ []) do
    default_opts = [pretty: true, width: 100, syntax_colors: syntax_colors()]
    Keyword.merge(default_opts, opts)
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
