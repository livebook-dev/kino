defmodule Kino.Counter do
  @moduledoc false

  @table_name __MODULE__

  @doc """
  Initializes resources for global counters.
  """
  @spec initialize() :: :ok
  def initialize() do
    :ets.new(@table_name, [:set, :named_table, :public])
    :ok
  end

  @doc """
  Increments the given counter and returns the new value.
  """
  @spec next(term()) :: integer()
  def next(key) do
    :ets.update_counter(@table_name, key, {2, 1}, {key, 0})
  end

  @doc """
  Sets the counter to `value` unless it already has a higher value.

  Returns the new counter value.
  """
  @spec put_max(term(), integer()) :: integer()
  def put_max(key, value) do
    [_, counter] =
      :ets.update_counter(@table_name, key, [{2, -1, value, value - 1}, {2, 1}], {key, 0})

    counter
  end
end
