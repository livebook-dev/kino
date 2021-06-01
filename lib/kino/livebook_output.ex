defmodule Kino.LivebookOutput do
  @moduledoc """
  A number of output formats supported by Livebook.
  """

  @typedoc """
  Livebook cell output may be one of these values
  and is rendered accordingly.
  """
  @type t ::
          :ignored
          # Regular text, adjacent such outputs can be treated as a whole
          | binary()
          # Standalone text block
          | {:text, binary()}
          # Vega-Lite graphic
          | {:vega_lite_static, spec :: map()}
          # Vega-Lite graphic with dynamic data
          | {:vega_lite_dynamic, widget_process :: pid()}

  def inline_text(text) when is_binary(text) do
    text
  end

  def text(text) when is_binary(text) do
    {:text, text}
  end

  def vega_lite_static(spec) when is_map(spec) do
    {:vega_lite_static, spec}
  end

  def vega_lite_dynamic(pid) when is_pid(pid) do
    {:vega_lite_dynamic, pid}
  end

  def inspect(term) do
    inspected = inspect(term, inspect_opts())
    text(inspected)
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
