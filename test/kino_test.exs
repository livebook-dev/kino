defmodule KinoTest do
  use Kino.LivebookCase, async: true

  import ExUnit.CaptureLog

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

    test "ignores failures" do
      log =
        capture_log(fn ->
          Stream.iterate(0, &(&1 + 1))
          |> Stream.take(2)
          |> Kino.animate(fn i ->
            1 = i
            i
          end)

          assert_output({:frame, [], %{ref: ref, type: :default}})
          assert_output({:frame, [{:text, "\e[34m1\e[0m"}], %{ref: ^ref, type: :replace}})
        end)

      assert log =~ "Kino.animate"
      assert log =~ "(MatchError) no match of right hand side value: 0"
    end
  end

  describe "animate/3" do
    test "renders a new output for every consumed item and accumulates state" do
      Stream.iterate(0, &(&1 + 1))
      |> Stream.take(2)
      |> Kino.animate(0, fn i, state ->
        {:cont, i + state, i + state}
      end)

      assert_output({:frame, [], %{ref: ref, type: :default}})
      assert_output({:frame, [{:text, "\e[34m0\e[0m"}], %{ref: ^ref, type: :replace}})
      assert_output({:frame, [{:text, "\e[34m1\e[0m"}], %{ref: ^ref, type: :replace}})
    end

    test "ignores failures" do
      log =
        capture_log(fn ->
          Stream.iterate(0, &(&1 + 1))
          |> Stream.take(4)
          |> Kino.animate(0, fn i, state ->
            true = i in [1, 3]
            {:cont, i + state, i + state}
          end)

          assert_output({:frame, [], %{ref: ref, type: :default}})
          assert_output({:frame, [{:text, "\e[34m1\e[0m"}], %{ref: ^ref, type: :replace}})
          assert_output({:frame, [{:text, "\e[34m4\e[0m"}], %{ref: ^ref, type: :replace}})
        end)

      assert log =~ "Kino.animate"
      assert log =~ "** (MatchError) no match of right hand side value: false"
    end
  end

  describe "listen/2" do
    test "consumes stream items" do
      myself = self()

      Stream.iterate(0, &(&1 + 1))
      |> Stream.take(2)
      |> Kino.listen(fn i ->
        send(myself, {:item, i})
      end)

      assert_receive {:item, 0}
      assert_receive {:item, 1}
    end

    test "with control events" do
      button = Kino.Control.button("Click")
      myself = self()
      trace_subscription()

      Kino.listen(button, fn event ->
        send(myself, event)
      end)

      assert_receive {:trace, _, :receive, {:"$gen_cast", {:subscribe, ref, _, _}}}
                     when button.attrs.ref == ref

      info = %{origin: "client1"}
      send(button.attrs.destination, {:event, button.attrs.ref, info})
      send(button.attrs.destination, {:event, button.attrs.ref, info})

      assert_receive ^info
      assert_receive ^info
    end

    test "ignores failures" do
      log =
        capture_log(fn ->
          myself = self()

          Stream.iterate(0, &(&1 + 1))
          |> Stream.take(2)
          |> Kino.listen(fn i ->
            1 = i

            send(myself, {:item, i})
          end)

          assert_receive {:item, 1}
        end)

      assert log =~ "Kino.listen"
      assert log =~ "** (MatchError) no match of right hand side value: 0"
    end
  end

  describe "listen/3" do
    test "consumes stream items and accumulates state" do
      myself = self()

      Stream.iterate(0, &(&1 + 1))
      |> Stream.take(2)
      |> Kino.listen(0, fn i, state ->
        send(myself, {:item, i + state})
        {:cont, i + state}
      end)

      assert_receive {:item, 0}
      assert_receive {:item, 1}
    end

    test "with control events" do
      button = Kino.Control.button("Click")
      myself = self()
      trace_subscription()

      button
      |> Kino.listen(0, fn _event, counter ->
        send(myself, {:counter, counter + 1})
        {:cont, counter + 1}
      end)

      assert_receive {:trace, _, :receive, {:"$gen_cast", {:subscribe, ref, _, _}}}
                     when button.attrs.ref == ref

      info = %{origin: "client1"}
      send(button.attrs.destination, {:event, button.attrs.ref, info})
      send(button.attrs.destination, {:event, button.attrs.ref, info})

      assert_receive {:counter, 1}
      assert_receive {:counter, 2}
    end

    test "ignores failures" do
      log =
        capture_log(fn ->
          myself = self()

          Stream.iterate(0, &(&1 + 1))
          |> Stream.take(4)
          |> Kino.listen(0, fn i, state ->
            true = i in [1, 3]
            send(myself, {:item, i + state})
            {:cont, i + state}
          end)

          assert_receive {:item, 1}
          assert_receive {:item, 4}
        end)

      assert log =~ "Kino.listen"
      assert log =~ "** (MatchError) no match of right hand side value: false"
    end
  end

  describe "async_listen/2" do
    test "concurrently processes stream items" do
      myself = self()

      Stream.iterate(0, &(&1 + 1))
      |> Stream.take(2)
      |> Kino.async_listen(fn i ->
        send(myself, {:item, i})
        Process.sleep(:infinity)
      end)

      assert_receive {:item, 0}
      assert_receive {:item, 1}
    end

    test "with control events" do
      button = Kino.Control.button("Click")
      myself = self()
      trace_subscription()

      Kino.async_listen(button, fn event ->
        send(myself, event)
        Process.sleep(:infinity)
      end)

      assert_receive {:trace, _, :receive, {:"$gen_cast", {:subscribe, ref, _, _}}}
                     when button.attrs.ref == ref

      info = %{origin: "client1"}
      send(button.attrs.destination, {:event, button.attrs.ref, info})
      send(button.attrs.destination, {:event, button.attrs.ref, info})

      assert_receive ^info
      assert_receive ^info
    end

    test "ignores failures" do
      log =
        capture_log(fn ->
          myself = self()

          Stream.iterate(0, &(&1 + 1))
          |> Stream.take(2)
          |> Kino.async_listen(fn i ->
            send(myself, {:item, self()})
            1 = i
          end)

          assert_receive {:item, pid1}
          assert_receive {:item, pid2}
          await_process(pid1)
          await_process(pid2)
        end)

      assert log =~ "Kino.async_listen"
      assert log =~ "** (MatchError) no match of right hand side value: 0"
    end
  end

  defp await_process(pid) do
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, :process, _object, _reason}
  end

  defp trace_subscription do
    :erlang.trace(Process.whereis(Kino.SubscriptionManager), true, [:receive, tracer: self()])
    :erlang.trace_pattern(:receive, [], [])
  end
end
