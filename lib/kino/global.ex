defmodule Kino.Global do
  @moduledoc false

  @table_name __MODULE__

  @doc """
  Initializes resources for global attrs.
  """
  @spec initialize() :: :ok
  def initialize() do
    :ets.new(@table_name, [:set, :named_table, :public])
    :ok
  end

  @doc """
  Updates the given attr value.
  """
  @spec insert(term(), term()) :: boolean()
  def insert(key, value) do
    maybe_clear_secret(key)
    :ets.insert(@table_name, {key, value})
  end

  @doc """
  Returns the attr value.
  """
  @spec lookup(term()) :: term()
  def lookup(key) do
    :ets.lookup(@table_name, key)
  end

  defp maybe_clear_secret(key) do
    case String.split_at(key, -7) do
      {key, "_secret"} -> :ets.delete(@table_name, key)
      _ -> :ets.delete(@table_name, "#{key}_secret")
    end
  end
end
