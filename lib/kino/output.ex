defmodule Kino.Output do
  @moduledoc false

  import Kernel, except: [inspect: 2]

  @typedoc """
  Livebook cell output may be one of these values and gets rendered
  accordingly.

  See `t:Livebook.Runtime.output/0` for the detailed format.
  """
  @type t :: map()

  @type ref :: String.t()

  @doc """
  Returns `t:text/0` with the inspected term.
  """
  @spec inspect(term(), keyword()) :: t()
  def inspect(term, opts \\ []) do
    inspected = Kernel.inspect(term, inspect_opts(opts))
    %{type: :terminal_text, text: inspected, chunk: false}
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
