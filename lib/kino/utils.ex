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
         {:dictionary, dictionary} <- :erpc.call(node(pid), Process, :info, [pid, :dictionary]),
         {:supervisor, _, _} <- dictionary[:"$initial_call"],
         do: true,
         else: (_ -> false)
  end

  @doc """
  Determines image type looking for the magic number in the binary.
  """
  @spec get_image_type(binary()) :: Kino.Image.common_image_type() | nil
  def get_image_type(<<0xFF, 0xD8, 0xFF, 0xE0, _rest::binary>>), do: :jpeg
  def get_image_type(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _rest::binary>>), do: :png
  def get_image_type(<<0x3C, 0x3F, 0x78, 0x6D, 0x6C, 0x20, _rest::binary>>), do: :svg

  def get_image_type(<<0x47, 0x49, 0x46, 0x38, x::8, 0x61, _rest::binary>>)
      when x in [0x37, 0x39],
      do: :gif

  def get_image_type(_image), do: nil
end
