defmodule KinoTest.Livebook do
  @doc """
  Asserts the given output is sent to within `timeout`.

  ## Examples

      assert_output({:markdown, "_hey_"})
  """
  defmacro assert_output(output, timeout \\ 100) do
    quote do
      assert_receive {:livebook_put_output, unquote(output)}, unquote(timeout)
    end
  end
end
