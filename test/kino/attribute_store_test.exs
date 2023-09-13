defmodule Kino.AttributeStoreTets do
  use ExUnit.Case, async: true

  alias Kino.AttributeStore

  describe "counter_next/2" do
    test "returns the default value if the counter doesn't exist", %{test: test} do
      assert AttributeStore.counter_next(test) == 1
    end

    test "increments the counter on every call", %{test: test} do
      AttributeStore.counter_next(test)

      assert AttributeStore.counter_next(test) == 2
      assert AttributeStore.counter_next(test) == 3
      assert AttributeStore.counter_next(test) == 4
    end
  end

  describe "counter_put_max/2" do
    test "sets the given value if the counter doesn't exist", %{test: test} do
      assert AttributeStore.counter_put_max(test, 10) == 10
    end

    test "keeps existing value if the given one is lower or equal", %{test: test} do
      AttributeStore.counter_put_max(test, 10)

      assert AttributeStore.counter_put_max(test, 5) == 10
      assert AttributeStore.counter_put_max(test, 10) == 10
    end

    test "sets the given value if higher than the current one", %{test: test} do
      AttributeStore.counter_put_max(test, 10)

      assert AttributeStore.counter_put_max(test, 11) == 11
      assert AttributeStore.counter_put_max(test, 15) == 15
    end
  end

  describe "get_attr/1" do
    test "returns the default value if the shared attr doesn't exist", %{test: test} do
      assert AttributeStore.get_attribute({test, :no_attr}) == nil
    end

    test "returns the value if the shared attr exist", %{test: test} do
      AttributeStore.put_attribute({test, :shared_attr}, "plain value")
      assert AttributeStore.get_attribute({test, :shared_attr}) == "plain value"
    end
  end
end
