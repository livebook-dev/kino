defmodule Kino.TreeTest do
  use Kino.LivebookCase, async: true

  defmodule User do
    defstruct [:email]
  end

  describe "to_node/1" do
    import Kino.Tree, only: [to_node: 1]

    test "returns strings as string nodes" do
      assert %{type: "string", value: "some string"} = to_node("some string")
    end

    test "returns atoms as atom nodes with string value" do
      assert %{type: "atom", value: "Elixir.SomeModule"} = to_node(SomeModule)
    end

    test "returns integers as integer nodes" do
      assert %{type: "integer", value: 100} = to_node(100)
    end

    test "returns floats as float nodes" do
      assert %{type: "float", value: 100.0} = to_node(100.0)
    end

    test "returns tuples as tuple nodes with children" do
      assert %{
               type: "tuple",
               value: nil,
               children: [
                 %{type: "integer", value: 1},
                 %{type: "string", value: "two"}
               ]
             } = to_node({1, "two"})
    end

    test "returns lists as list nodes with children" do
      assert %{
               type: "list",
               value: nil,
               children: [
                 %{type: "integer", value: 1},
                 %{type: "string", value: "two"}
               ]
             } = to_node([1, "two"])
    end

    test "returns keywords as a list nodes with key-value children" do
      assert %{
               type: "list",
               value: nil,
               children: [
                 %{
                   type: "atom",
                   key: %{type: "atom", value: "foo"},
                   value: "oof"
                 },
                 %{
                   type: "atom",
                   key: %{type: "atom", value: "bar"},
                   value: "baz"
                 }
               ]
             } = to_node(foo: :oof, bar: :baz)
    end

    test "returns maps as map nodes with sorted key-value children" do
      assert %{
               type: "map",
               value: nil,
               children: [
                 %{
                   type: "atom",
                   key: %{type: "atom", value: "bar"},
                   value: "baz"
                 },
                 %{
                   type: "atom",
                   key: %{type: "atom", value: "foo"},
                   value: "oof"
                 }
               ]
             } = to_node(%{foo: :oof, bar: :baz})
    end

    test "uses Inspect protocol for compound keys" do
      assert %{
               type: "map",
               value: nil,
               children: [
                 %{
                   type: "atom",
                   key: %{type: "compoundkey", value: "{1, 2}"},
                   value: "true"
                 }
               ]
             } = to_node(%{{1, 2} => true})
    end

    test "returns structs as struct nodes" do
      assert %{
               type: "struct",
               value: "Elixir.Kino.TreeTest.User",
               children: [
                 %{
                   type: "string",
                   key: %{type: "atom", value: "email"},
                   value: "user@example.com"
                 }
               ]
             } = to_node(%User{email: "user@example.com"})
    end

    test "returns other terms as string nodes using Inspect protocol" do
      assert %{type: "string", value: "#PID<" <> _rest} = to_node(self())
    end

    test "handles nested data" do
      assert %{
               type: "map",
               value: nil,
               children: [
                 %{
                   type: "list",
                   key: %{type: "atom", value: "items"},
                   value: nil,
                   children: [
                     %{type: "integer", value: 1},
                     %{type: "atom", value: "nil"},
                     %{
                       type: "tuple",
                       children: [
                         %{type: "integer", value: 1},
                         %{type: "integer", value: 2}
                       ]
                     }
                   ]
                 }
               ]
             } = to_node(%{items: [1, nil, {1, 2}]})
    end
  end
end
