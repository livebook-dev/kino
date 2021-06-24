defmodule Kino.Config do
  @moduledoc false

  @keys [:inspect]

  @spec configuration() :: keyword()
  def configuration() do
    Application.get_all_env(:kino) |> Keyword.take(@keys)
  end

  @spec configuration(atom()) :: term()
  def configuration(key, default \\ nil) when key in @keys do
    Application.get_env(:kino, key, default)
  end

  @spec configure(keyword()) :: :ok
  def configure(options) do
    Enum.each(options, &validate_option/1)

    configuration()
    |> Keyword.merge(options, &merge_option/3)
    |> update_configuration()

    :ok
  end

  defp validate_option({:inspect, new}) when is_list(new), do: :ok

  defp merge_option(:inspect, old, new) when is_list(new), do: Keyword.merge(old, new)

  defp update_configuration(config) do
    Enum.each(config, fn {key, value} when key in @keys ->
      Application.put_env(:kino, key, value)
    end)
  end
end
