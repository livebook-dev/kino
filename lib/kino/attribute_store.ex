defmodule Kino.AttributeStore do
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
  Increments the given counter and returns the new value.
  """
  @spec counter_next(term()) :: integer()
  def counter_next(key) do
    :ets.update_counter(@table_name, key, {2, 1}, {key, 0})
  end

  @doc """
  Sets the counter to `value` unless it already has a higher value.

  Returns the new counter value.
  """
  @spec counter_put_max(term(), integer()) :: integer()
  def counter_put_max(key, value) do
    [_, counter] =
      :ets.update_counter(@table_name, key, [{2, -1, value, value - 1}, {2, 1}], {key, 0})

    counter
  end

  @doc """
  Puts the shared attribute value.
  """
  @spec put_attribute(term(), term()) :: boolean()
  def put_attribute(key, value) do
    :ets.insert(@table_name, {key, value})
  end

  @doc """
  Returns the attribute value for a given key.
  """
  @spec get_attribute(term()) :: term()
  def get_attribute(key, default \\ nil) do
    case :ets.lookup(@table_name, key) do
      [] -> default
      [{_key, value} | _] -> value
    end
  end
end
