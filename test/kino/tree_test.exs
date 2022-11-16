defmodule Kino.TreeTest do
  use Kino.LivebookCase, async: true

  defp tree(input) do
    %Kino.JS{ref: ref} = Kino.Tree.new(input)
    send(Kino.JS.DataStore, {:connect, self(), %{origin: "client:#{inspect(self())}", ref: ref}})
    assert_receive {:connect_reply, data, %{ref: ^ref}}
    data
  end

  defmodule User do
    defstruct [:email]
  end

  test "renders strings as string nodes" do
    assert %{type: "string", value: "some string"} = tree("some string")
  end

  test "renders atoms as atom nodes with string value" do
    assert %{type: "atom", value: "Elixir.SomeModule"} = tree(SomeModule)
  end

  test "renders integers as integer nodes" do
    assert %{type: "integer", value: 100} = tree(100)
  end

  test "renders floats as float nodes" do
    assert %{type: "float", value: 100.0} = tree(100.0)
  end

  test "renders tuples as tuple nodes with children" do
    assert %{
              type: "tuple",
              value: nil,
              children: [
                %{type: "integer", value: 1},
                %{type: "string", value: "two"}
              ]
            } = tree({1, "two"})
  end

  test "renders lists as list nodes with children" do
    assert %{
              type: "list",
              value: nil,
              children: [
                %{type: "integer", value: 1},
                %{type: "string", value: "two"}
              ]
            } = tree([1, "two"])
  end

  test "renders keywords as a list nodes with key-value children" do
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
            } = tree(foo: :oof, bar: :baz)
  end

  test "renders maps as map nodes with sorted key-value children" do
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
            } = tree(%{foo: :oof, bar: :baz})
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
            } = tree(%{{1, 2} => true})
  end

  test "renders structs as struct nodes" do
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
            } = tree(%User{email: "user@example.com"})
  end

  test "renders other terms as string nodes using Inspect protocol" do
    assert %{type: "string", value: "#PID<" <> _rest} = tree(self())
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
            } = tree(%{items: [1, nil, {1, 2}]})
  end
end
