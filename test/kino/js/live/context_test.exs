defmodule Kino.JS.Live.ContextTest do
  use ExUnit.Case, async: true

  alias Kino.JS.Live.Context

  describe "assign/2" do
    test "stores value under the given key if it doesn't exist" do
      ctx = Context.new()
      assert %{assigns: %{count: 1}} = Context.assign(ctx, count: 1)
    end

    test "overrides value if the given key already exists" do
      ctx = Context.new() |> Context.assign(count: 1)
      assert %{assigns: %{count: 2}} = Context.assign(ctx, count: 2)
    end
  end

  describe "update/3" do
    test "raises an error when nonexistent key is given" do
      ctx = Context.new()

      assert_raise KeyError, ~r/:count/, fn ->
        Context.update(ctx, :count, &(&1 + 1))
      end
    end

    test "updates value with the given function" do
      ctx = Context.new() |> Context.assign(count: 1)
      assert %{assigns: %{count: 2}} = Context.update(ctx, :count, &(&1 + 1))
    end
  end
end
