defmodule Kino.TreeTest do
  use Kino.LivebookCase, async: true

  defp tree(input) do
    %Kino.Layout{type: :grid, outputs: [js: %{js_view: %{ref: ref}}]} = Kino.Tree.new(input)
    send(Kino.JS.DataStore, {:connect, self(), %{origin: "client:#{inspect(self())}", ref: ref}})
    assert_receive {:connect_reply, data, %{ref: ^ref}}
    data
  end

  defmodule User do
    defstruct [:email]
  end

  test "renders strings as string nodes" do
    assert %{text: ~s("some string"), children: nil} = tree("some string")
  end

  test "renders atoms as nodes with inspected value" do
    assert %{text: ":foo", children: nil} = tree(:foo)
    assert %{text: ~s(:"I need quotes"), children: nil} = tree(:"I need quotes")
    assert %{text: "SomeModule", children: nil} = tree(SomeModule)
  end

  test "renders numbers as nodes with inspected value" do
    assert %{text: "100", children: nil} = tree(100)
    assert %{text: "100.0", children: nil} = tree(100.0)
  end

  test "renders tuples as nodes with children" do
    assert %{
             text: "{...}",
             expanded: %{prefix: "{", suffix: "}"},
             children: [
               %{text: "1", children: nil}
             ]
           } = tree({1})
  end

  test "handles deep nesting" do
    assert %{
             text: "{...}",
             expanded: %{prefix: "{", suffix: "}"},
             children: [
               %{
                 text: "{...}",
                 expanded: %{prefix: "{", suffix: "}"},
                 children: [
                   %{text: "1", children: nil}
                 ]
               }
             ]
           } = tree({{1}})
  end

  test "adds trailing commas to all but last child" do
    assert %{
             text: "{...}",
             expanded: %{prefix: "{", suffix: "}"},
             children: [
               %{text: "1,", children: nil},
               %{
                 text: "{...},",
                 expanded: %{prefix: "{", suffix: "},"},
                 children: [
                   %{text: ":x,", children: nil},
                   %{text: ":y", children: nil}
                 ]
               },
               %{text: ":three", children: nil}
             ]
           } = tree({1, {:x, :y}, :three})
  end

  test "renders lists as nodes with children" do
    assert %{
             text: "[...]",
             expanded: %{prefix: "[", suffix: "]"},
             children: [
               %{text: "1", children: nil}
             ]
           } = tree([1])
  end

  test "renders keywords as nodes with key-value children" do
    assert %{
             text: "[...]",
             expanded: %{prefix: "[", suffix: "]"},
             children: [
               %{text: "foo: :bar", children: nil}
             ]
           } = tree(foo: :bar)
  end

  test "renders maps as nodes with key-value children" do
    assert %{
             text: "%{...}",
             expanded: %{prefix: "%{", suffix: "}"},
             children: [
               %{text: "foo: :bar", children: nil}
             ]
           } = tree(%{foo: :bar})
  end

  test "uses the arrow for non-atom keys" do
    assert %{
             text: "%{...}",
             expanded: %{prefix: "%{", suffix: "}"},
             children: [
               %{text: ~s("foo" => "bar"), children: nil}
             ]
           } = tree(%{"foo" => "bar"})
  end

  test "sorts maps by key" do
    assert %{
             text: "%{...}",
             expanded: %{prefix: "%{", suffix: "}"},
             children: [
               %{text: "bar: :baz,", children: nil},
               %{text: "foo: :oof", children: nil}
             ]
           } = tree(%{foo: :oof, bar: :baz})
  end

  test "uses Inspect protocol for compound keys" do
    assert %{
             text: "%{...}",
             expanded: %{prefix: "%{", suffix: "}"},
             children: [
                %{text: "{1, 2} => true", children: nil}
             ]
           } = tree(%{{1, 2} => true})
  end

  test "renders structs as nodes with children" do
    assert %{
             text: "%Kino.TreeTest.User{...}",
             expanded: %{prefix: "%Kino.TreeTest.User{", suffix: "}"},
             children: [
               %{text: ~s(email: "user@example.com"), children: nil}
             ]
           } = tree(%User{email: "user@example.com"})
  end

  test "renders other terms as string nodes using Inspect protocol" do
    assert %{text: "#PID<" <> _rest, children: nil} = tree(self())
  end
end
