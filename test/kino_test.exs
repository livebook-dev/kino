defmodule KinoUnitTest do
  use ExUnit.Case, async: true

  describe "inspect/2" do
    test "sends a text output to the group leader" do
      gl =
        spawn(fn ->
          assert_receive {:io_request, from, ref, {:livebook_put_output, output}}
          send(from, {:io_reply, ref, :ok})

          assert {:text, "\e[34m:hey\e[0m"} = output
        end)

      Process.group_leader(self(), gl)

      Kino.inspect(:hey)

      await_process(gl)
    end
  end

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

      await_process(pid)
    end
  end

  defp await_process(pid) do
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, :process, _object, _reason}
  end
end
