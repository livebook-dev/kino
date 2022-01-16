defmodule Kino.LivebookCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import unquote(__MODULE__)
    end
  end

  setup do
    gl = start_supervised!({KinoTest.GroupLeader, self()})
    Process.group_leader(self(), gl)
    :ok
  end

  # Helpers

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
