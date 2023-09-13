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
    :ets.insert(@table_name, {key, value})
  end

  @doc """
  Returns the attr value.
  """
  @spec lookup(term()) :: term()
  def lookup(key) do
    :ets.lookup(@table_name, key)
  end
end
