defmodule KinoTest do
  use ExUnit.Case, async: true

  describe "start_child/1" do
    test "raises in a process already started as a child" do
      {:ok, pid} =
        Kino.start_child(
          {Task,
           fn ->
             assert_raise ArgumentError, ~r/could not start .* using Kino.start_child/, fn ->
               Kino.start_child({Task, fn -> :ok end})
             end
           end}
        )

      ref = Process.monitor(pid)

      assert_receive {:DOWN, ^ref, :process, _object, _reason}
    end
  end
end
