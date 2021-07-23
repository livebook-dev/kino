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
end
