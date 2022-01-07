defmodule Kino.LivebookCase do
  use ExUnit.CaseTemplate

  setup do
    original_gl = Process.group_leader()

    gl = start_supervised!({KinoTest.GroupLeader, self()})
    Process.group_leader(self(), gl)

    on_exit(fn ->
      Process.group_leader(self(), original_gl)
    end)
  end
end
