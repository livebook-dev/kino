defmodule Kino.Utils do
  @moduledoc false

  @doc """
  Returns keyword list keys that hold a truthy value.

  ## Examples

      iex> Kino.Utils.truthy_keys(cat: true, dog: false)
      [:cat]

      iex> Kino.Utils.truthy_keys(tea: :ok, coffee: nil)
      [:tea]
  """
  @spec truthy_keys(keyword()) :: list(atom())
  def truthy_keys(keywords) when is_list(keywords) do
    keywords
    |> Enum.filter(&elem(&1, 1))
    |> Keyword.keys()
  end

  @doc """
  Checks if the given module exports the given function.

  Loads the module if not loaded.
  """
  @spec has_function?(module(), atom(), arity()) :: boolean()
  def has_function?(module, function, arity) do
    Code.ensure_loaded?(module) and function_exported?(module, function, arity)
  end

  @doc """
  Checks if the given process is a supervisor.
  """
  @spec supervisor?(atom() | pid()) :: boolean
  def supervisor?(supervisor) do
    with pid when is_pid(pid) <- GenServer.whereis(supervisor),
         {:dictionary, dictionary} <- Process.info(pid, :dictionary),
         {:supervisor, _, _} <- dictionary[:"$initial_call"],
         do: true,
         else: (_ -> false)
  end
end
