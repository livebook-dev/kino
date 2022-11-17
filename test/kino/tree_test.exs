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
    assert %{content: ~s("some string"), children: nil} = tree("some string")
  end

  test "renders atoms as nodes with inspected value" do
    assert %{content: ":foo", children: nil} = tree(:foo)
    assert %{content: ~s(:"I need quotes"), children: nil} = tree(:"I need quotes")
    assert %{content: "SomeModule", children: nil} = tree(SomeModule)
  end

  test "renders numbers as nodes with inspected value" do
    assert %{content: "100", children: nil} = tree(100)
    assert %{content: "100.0", children: nil} = tree(100.0)
  end

  test "renders tuples as nodes with children" do
    assert %{
             content: "{...}",
             expanded: %{prefix: "{", suffix: "}"},
             children: [
               %{content: "1", children: nil}
             ]
           } = tree({1})
  end

  test "handles deep nesting" do
    assert %{
             content: "{...}",
             expanded: %{prefix: "{", suffix: "}"},
             children: [
               %{
                 content: "{...}",
                 expanded: %{prefix: "{", suffix: "}"},
                 children: [
                   %{content: "1", children: nil}
                 ]
               }
             ]
           } = tree({{1}})
  end

  test "adds trailing commas to all but last child" do
    assert %{
             content: "{...}",
             expanded: %{prefix: "{", suffix: "}"},
             children: [
               %{content: "1,", children: nil},
               %{
                 content: "{...},",
                 expanded: %{prefix: "{", suffix: "},"},
                 children: [
                   %{content: ":x,", children: nil},
                   %{content: ":y", children: nil}
                 ]
               },
               %{content: ":three", children: nil}
             ]
           } = tree({1, {:x, :y}, :three})
  end

  test "renders lists as nodes with children" do
    assert %{
             content: "[...]",
             expanded: %{prefix: "[", suffix: "]"},
             children: [
               %{content: "1", children: nil}
             ]
           } = tree([1])
  end

  test "renders keywords as nodes with key-value children" do
    assert %{
             content: "[...]",
             expanded: %{prefix: "[", suffix: "]"},
             children: [
               %{content: "foo: :bar", children: nil}
             ]
           } = tree(foo: :bar)
  end

  test "renders maps as nodes with key-value children" do
    assert %{
             content: "%{...}",
             expanded: %{prefix: "%{", suffix: "}"},
             children: [
               %{content: "foo: :bar", children: nil}
             ]
           } = tree(%{foo: :bar})
  end

  test "uses the arrow for non-atom keys" do
    assert %{
             content: "%{...}",
             expanded: %{prefix: "%{", suffix: "}"},
             children: [
               %{content: ~s("foo" => "bar"), children: nil}
             ]
           } = tree(%{"foo" => "bar"})
  end

  test "sorts maps by key" do
    assert %{
             content: "%{...}",
             expanded: %{prefix: "%{", suffix: "}"},
             children: [
               %{content: "bar: :baz,", children: nil},
               %{content: "foo: :oof", children: nil}
             ]
           } = tree(%{foo: :oof, bar: :baz})
  end

  test "uses Inspect protocol for compound keys" do
    assert %{
             content: "%{...}",
             expanded: %{prefix: "%{", suffix: "}"},
             children: [
               %{content: "{1, 2} => true", children: nil}
             ]
           } = tree(%{{1, 2} => true})
  end

  test "renders structs as nodes with children" do
    assert %{
             content: "%Kino.TreeTest.User{...}",
             expanded: %{prefix: "%Kino.TreeTest.User{", suffix: "}"},
             children: [
               %{content: ~s(email: "user@example.com"), children: nil}
             ]
           } = tree(%User{email: "user@example.com"})
  end

  test "uses special handling for regexes" do
    assert %{content: "~r/foobar/", children: nil} = tree(~r/foobar/)
    assert %{content: "~r//", children: nil} = tree(%Regex{})
  end

  test "renders other terms as string nodes using Inspect protocol" do
    assert %{content: "#PID<" <> _rest, children: nil} = tree(self())
  end
end
