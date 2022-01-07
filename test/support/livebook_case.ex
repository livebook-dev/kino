defmodule Kino.LivebookCase do
  use ExUnit.CaseTemplate

  setup do
    gl = start_supervised!({KinoTest.GroupLeader, self()})
    Process.group_leader(self(), gl)
    :ok
  end
end
