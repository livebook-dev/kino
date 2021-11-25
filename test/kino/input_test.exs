defmodule Kino.InputTest do
  use ExUnit.Case, async: true

  describe "select/3" do
    test "raises an error for empty option list" do
      assert_raise ArgumentError, "expected at least on option, got: []", fn ->
        Kino.Input.select("Language", [])
      end
    end

    test "raises an error when the default value does not match any option" do
      assert_raise ArgumentError, "expected :default to be either of :en, :fr, got: :pl", fn ->
        Kino.Input.select("Language", [en: "English", fr: "Français"], default: :pl)
      end
    end
  end

  describe "range/2" do
    test "raises an error when min is less than max" do
      assert_raise ArgumentError, "expected :min to be less than :max, got: 10 and 0", fn ->
        Kino.Input.range("Length", min: 10, max: 0)
      end
    end

    test "raises an error when step is negative" do
      assert_raise ArgumentError, "expected :step to be positive, got: -1", fn ->
        Kino.Input.range("Length", step: -1)
      end
    end

    test "raises an error when the default is out of range" do
      assert_raise ArgumentError, "expected :default to be between :min and :max, got: 20", fn ->
        Kino.Input.range("Length", min: 0, max: 10, default: 20)
      end
    end
  end
end
