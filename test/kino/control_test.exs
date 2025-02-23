defmodule Kino.ControlTest do
  use ExUnit.Case, async: true

  describe "keyboard/1" do
    test "raises an error for empty option list" do
      assert_raise ArgumentError, "expected at least one event, got: []", fn ->
        Kino.Control.keyboard([])
      end
    end

    test "raises an error when an invalid event is given" do
      assert_raise ArgumentError,
                   "expected event to be either :keyup, :keydown or :status, got: :keyword",
                   fn ->
                     Kino.Control.keyboard([:keyword])
                   end
    end

    test "raises an error when invalid options are passed" do
      assert_raise ArgumentError,
                   "when passed, :default_handlers must be one of :off, :on or :disable_only, got: :foo",
                   fn ->
                     Kino.Control.keyboard([:keydown], default_handlers: :foo)
                   end
    end
  end

  describe "form/1" do
    test "raises an error for empty field list" do
      assert_raise ArgumentError, "expected at least one field, got: []", fn ->
        Kino.Control.form([], submit: "Send")
      end
    end

    test "raises an error when value other than input is given" do
      assert_raise ArgumentError,
                   "expected each field to be a Kino.Input widget, got: %{id: 1} for :name",
                   fn ->
                     Kino.Control.form(name: %{id: 1}, submit: "Send")
                   end
    end

    test "raises an error when neither submit nor change trigger is enabled" do
      assert_raise ArgumentError,
                   "expected either :submit or :report_changes option to be enabled",
                   fn ->
                     Kino.Control.form(name: Kino.Input.text("Name"))
                   end
    end

    test "supports nil fields" do
      assert %Kino.Control{attrs: %{fields: [name: %{}, age: nil]}} =
               Kino.Control.form([name: Kino.Input.text("Name"), age: nil],
                 submit: "Send"
               )
    end

    test "supports boolean values for :reset_on_submit" do
      assert %Kino.Control{attrs: %{reset_on_submit: [:name]}} =
               Kino.Control.form([name: Kino.Input.text("Name")],
                 submit: "Send",
                 reset_on_submit: true
               )
    end

    test "supports boolean values for :report_changes" do
      assert %Kino.Control{attrs: %{report_changes: %{name: true}}} =
               Kino.Control.form([name: Kino.Input.text("Name")], report_changes: true)
    end
  end

  describe "subscribe/2" do
    test "subscribes to control events" do
      button = Kino.Control.button("Name")

      Kino.Control.subscribe(button, :name)

      info = %{origin: "client1"}
      send(button.destination, {:event, button.ref, info})

      assert_receive {:name, ^info}
    end
  end

  describe "stream/1" do
    test "raises on invalid argument" do
      assert_raise ArgumentError,
                   "expected source to be either %Kino.Control{}, %Kino.Input{}, %Kino.JS.Live{} or {:interval, ms}, got: 10",
                   fn ->
                     Kino.Control.stream(10)
                   end
    end

    test "returns control event feed" do
      button = Kino.Control.button("Name")

      background_tick(fn ->
        info = %{origin: "client1"}
        send(button.destination, {:event, button.ref, info})
      end)

      events = button |> Kino.Control.stream() |> Enum.take(2)

      assert events == [%{origin: "client1"}, %{origin: "client1"}]

      # Assert that nothing leaks to the inbox
      refute_receive _, 2
    end

    test "supports interval" do
      events = 1 |> Kino.Control.interval() |> Kino.Control.stream() |> Enum.take(2)
      assert events == [%{type: :interval, iteration: 0}, %{type: :interval, iteration: 1}]
    end

    test "halts when the topic is cleared" do
      button = Kino.Control.button("Name")

      background_tick(fn ->
        info = %{origin: "client1"}
        send(button.destination, {:event, button.ref, info})
      end)

      events =
        button
        |> Kino.Control.stream()
        |> Enum.map(fn event ->
          send(button.destination, {:clear_topic, button.ref})
          event
        end)

      assert [%{origin: "client1"} | _] = events
    end

    test "supports Kino.JS.Live" do
      kino = Kino.TestModules.LiveCounter.new(0)

      background_tick(fn ->
        Kino.TestModules.LiveCounter.bump(kino, 1)
      end)

      events = kino |> Kino.Control.stream() |> Enum.take(2)
      assert events == [%{event: :bump, by: 1}, %{event: :bump, by: 1}]

      # Assert that nothing leaks to the inbox
      refute_receive _, 2
    end
  end

  describe "stream/1 with a list of sources" do
    test "raises on invalid source" do
      assert_raise ArgumentError,
                   "expected source to be either %Kino.Control{}, %Kino.Input{}, %Kino.JS.Live{} or {:interval, ms}, got: 10",
                   fn ->
                     Kino.Control.stream([10])
                   end
    end

    test "returns combined event feed for the given sources" do
      button = Kino.Control.button("Click")
      input = Kino.Input.text("Name")

      background_tick(fn ->
        send(button.destination, {:event, button.ref, %{origin: "client1"}})
        send(button.destination, {:event, input.ref, %{origin: "client2"}})
      end)

      events = [button, input] |> Kino.Control.stream() |> Enum.take(2)

      assert Enum.sort(events) == [%{origin: "client1"}, %{origin: "client2"}]
    end
  end

  describe "tagged_stream/1" do
    test "raises on invalid argument" do
      assert_raise ArgumentError, "expected a list of 2-element tuples, got: [0]", fn ->
        Kino.Control.tagged_stream([0])
      end

      assert_raise ArgumentError,
                   "expected source to be either %Kino.Control{}, %Kino.Input{}, %Kino.JS.Live{} or {:interval, ms}, got: 10",
                   fn ->
                     Kino.Control.tagged_stream(name: 10)
                   end
    end

    test "returns tagged event feed for the given sources" do
      button = Kino.Control.button("Click")
      input = Kino.Input.text("Name")

      background_tick(fn ->
        send(button.destination, {:event, button.ref, %{origin: "client1"}})
        send(input.destination, {:event, input.ref, %{origin: "client2"}})
      end)

      events =
        [click: button, name: input]
        |> Kino.Control.tagged_stream()
        |> Enum.take(2)

      assert Enum.sort(events) == [{:click, %{origin: "client1"}}, {:name, %{origin: "client2"}}]

      events =
        [{{:click, "button"}, button}, {{:name, "text"}, input}]
        |> Kino.Control.tagged_stream()
        |> Enum.take(2)

      assert Enum.sort(events) == [
               {{:click, "button"}, %{origin: "client1"}},
               {{:name, "text"}, %{origin: "client2"}}
             ]
    end
  end

  defp background_tick(fun) do
    pid =
      spawn(fn ->
        for _ <- Stream.cycle([:infinity]) do
          Process.sleep(1)
          fun.()
        end
      end)

    on_exit(fn -> Process.exit(pid, :kill) end)

    pid
  end
end
