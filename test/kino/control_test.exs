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

      info = %{origin: self()}
      send(button.attrs.destination, {:event, button.attrs.ref, info})

      assert_receive {:name, ^info}
    end
  end

  describe "stream/1" do
    test "returns control event feed" do
      button = Kino.Control.button("Name")

      pid =
        spawn(fn ->
          Process.sleep(1)
          info = %{origin: self()}
          send(button.attrs.destination, {:event, button.attrs.ref, info})
          send(button.attrs.destination, {:event, button.attrs.ref, info})
        end)

      events =
        button
        |> Kino.Control.stream()
        |> Enum.take(2)

      assert events == [%{origin: pid}, %{origin: pid}]
    end
  end
end
