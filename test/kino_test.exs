defmodule KinoTest do
  use Kino.LivebookCase, async: true

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

  describe "animate/2" do
    test "renders a new output for every consumed item" do
      Stream.iterate(0, &(&1 + 1))
      |> Stream.take(2)
      |> Kino.animate(fn i -> i end)

      assert_output({:frame, [], %{ref: ref, type: :default}})
      assert_output({:frame, [{:text, "\e[34m0\e[0m"}], %{ref: ^ref, type: :replace}})
      assert_output({:frame, [{:text, "\e[34m1\e[0m"}], %{ref: ^ref, type: :replace}})
    end
  end

  describe "animate/3" do
    test "renders a new output for every consumed item and accumulates state" do
      Stream.iterate(0, &(&1 + 1))
      |> Stream.take(2)
      |> Kino.animate(0, fn i, state ->
        {:cont, i + state, state + 1}
      end)

      assert_output({:frame, [], %{ref: ref, type: :default}})
      assert_output({:frame, [{:text, "\e[34m0\e[0m"}], %{ref: ^ref, type: :replace}})
      assert_output({:frame, [{:text, "\e[34m2\e[0m"}], %{ref: ^ref, type: :replace}})
    end
  end

  describe "listen/2" do
    test "asynchronously consumes stream items" do
      myself = self()

      Stream.iterate(0, &(&1 + 1))
      |> Stream.take(2)
      |> Kino.listen(fn i ->
        send(myself, {:item, i})
      end)

      assert_receive {:item, 0}
      assert_receive {:item, 1}
    end

    test "with control events stream" do
      button = Kino.Control.button("Click")

      myself = self()

      button
      |> Kino.Control.stream()
      |> Kino.listen(fn event ->
        send(myself, event)
      end)

      Process.sleep(1)
      info = %{origin: "client1"}
      send(button.attrs.destination, {:event, button.attrs.ref, info})
      send(button.attrs.destination, {:event, button.attrs.ref, info})

      assert_receive ^info
      assert_receive ^info
    end
  end

  describe "listen/3" do
    test "asynchronously consumes stream items and accumulates state" do
      myself = self()

      Stream.iterate(0, &(&1 + 1))
      |> Stream.take(2)
      |> Kino.listen(0, fn i, state ->
        send(myself, {:item, i + state})
        {:cont, state + 1}
      end)

      assert_receive {:item, 0}
      assert_receive {:item, 2}
    end

    test "with control events" do
      button = Kino.Control.button("Click")

      myself = self()

      button
      |> Kino.Control.stream()
      |> Kino.listen(0, fn _event, counter ->
        send(myself, {:counter, counter + 1})
        {:cont, counter + 1}
      end)

      Process.sleep(1)
      info = %{origin: "client1"}
      send(button.attrs.destination, {:event, button.attrs.ref, info})
      send(button.attrs.destination, {:event, button.attrs.ref, info})

      assert_receive {:counter, 1}
      assert_receive {:counter, 2}
    end
  end

  defp await_process(pid) do
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, :process, _object, _reason}
  end
end
