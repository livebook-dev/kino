defmodule Kino.CounterTets do
  use ExUnit.Case, async: true

  alias Kino.Counter

  describe "next/2" do
    test "returns the default value if the counter doesn't exist", %{test: test} do
      assert Counter.next(test) == 1
    end

    test "increments the counter on every call", %{test: test} do
      Counter.next(test)

      assert Counter.next(test) == 2
      assert Counter.next(test) == 3
      assert Counter.next(test) == 4
    end
  end

  describe "bump/2" do
    test "sets the given value if the counter doesn't exist", %{test: test} do
      assert Counter.put_max(test, 10) == 10
    end

    test "keeps existing value if the given one is lower or equal", %{test: test} do
      Counter.put_max(test, 10)

      assert Counter.put_max(test, 5) == 10
      assert Counter.put_max(test, 10) == 10
    end

    test "sets the given value if higher than the current one", %{test: test} do
      Counter.put_max(test, 10)

      assert Counter.put_max(test, 11) == 11
      assert Counter.put_max(test, 15) == 15
    end
  end
end
