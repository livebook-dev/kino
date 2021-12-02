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

  describe "subscribe/2" do
    test "subscribes to control events" do
      button = Kino.Control.button("Name")

      Kino.Control.subscribe(button, :name)

      info = %{origin: self()}
      send(button.attrs.destination, {:event, button.attrs.ref, info})

      assert_receive {:name, ^info}
    end
  end
end
