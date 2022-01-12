defmodule Kino.LivebookCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import KinoTest.Livebook
    end
  end

  setup do
    gl = start_supervised!({KinoTest.GroupLeader, self()})
    Process.group_leader(self(), gl)
    :ok
  end
end
