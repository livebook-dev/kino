defmodule Kino.TreeTest do
  use Kino.LivebookCase, async: true

  test "renders strings as string nodes" do
    assert %{kind: "binary", content: ~s("some string"), children: nil} =
             plaintext_tree("some string")
  end

  test "renders atoms as nodes with inspected value" do
    assert %{kind: "atom", content: ":foo", children: nil} = plaintext_tree(:foo)
    assert %{kind: "atom", content: ~s(:"quote me"), children: nil} = plaintext_tree(:"quote me")
    assert %{kind: "atom", content: "SomeModule", children: nil} = plaintext_tree(SomeModule)
  end

  test "renders numbers as nodes with inspected value" do
    assert %{kind: "number", content: "100", children: nil} = plaintext_tree(100)
    assert %{kind: "number", content: "100.0", children: nil} = plaintext_tree(100.0)
  end

  test "renders tuples as nodes with children" do
    assert %{
             kind: "tuple",
             content: "{...}",
             expanded_before: "{",
             expanded_after: "}",
             children: [
               %{kind: "number", content: "1", children: nil}
             ]
           } = plaintext_tree({1})
  end

  test "handles deep nesting" do
    assert %{
             kind: "tuple",
             content: "{...}",
             expanded_before: "{",
             expanded_after: "}",
             children: [
               %{
                 kind: "tuple",
                 content: "{...}",
                 expanded_before: "{",
                 expanded_after: "}",
                 children: [
                   %{kind: "number", content: "1", children: nil}
                 ]
               }
             ]
           } = plaintext_tree({{1}})
  end

  test "adds trailing commas to all but last child" do
    assert %{
             kind: "tuple",
             content: "{...}",
             expanded_before: "{",
             expanded_after: "}",
             children: [
               %{kind: "number", content: "1,", children: nil},
               %{
                 kind: "tuple",
                 content: "{...},",
                 expanded_before: "{",
                 expanded_after: "},",
                 children: [
                   %{kind: "atom", content: ":x,", children: nil},
                   %{kind: "atom", content: ":y", children: nil}
                 ]
               },
               %{kind: "atom", content: ":three", children: nil}
             ]
           } = plaintext_tree({1, {:x, :y}, :three})
  end

  test "renders lists as nodes with children" do
    assert %{
             kind: "list",
             content: "[...]",
             expanded_before: "[",
             expanded_after: "]",
             children: [
               %{kind: "number", content: "1", children: nil}
             ]
           } = plaintext_tree([1])
  end

  test "renders keywords as nodes with key-value children" do
    assert %{
             kind: "list",
             content: "[...]",
             expanded_before: "[",
             expanded_after: "]",
             children: [
               %{kind: "atom", content: "foo: :bar", children: nil}
             ]
           } = plaintext_tree(foo: :bar)
  end

  test "renders maps as nodes with key-value children" do
    assert %{
             kind: "map",
             content: "%{...}",
             expanded_before: "%{",
             expanded_after: "}",
             children: [
               %{kind: "atom", content: "foo: :bar", children: nil}
             ]
           } = plaintext_tree(%{foo: :bar})
  end

  test "uses the arrow for non-atom keys" do
    assert %{
             kind: "map",
             content: "%{...}",
             expanded_before: "%{",
             expanded_after: "}",
             children: [
               %{kind: "binary", content: ~s("foo" => "bar"), children: nil}
             ]
           } = plaintext_tree(%{"foo" => "bar"})
  end

  test "sorts maps by key" do
    assert %{
             kind: "map",
             content: "%{...}",
             expanded_before: "%{",
             expanded_after: "}",
             children: [
               %{kind: "atom", content: "bar: :baz,", children: nil},
               %{kind: "atom", content: "foo: :oof", children: nil}
             ]
           } = plaintext_tree(%{foo: :oof, bar: :baz})
  end

  test "uses Inspect protocol for compound keys" do
    assert %{
             kind: "map",
             content: "%{...}",
             expanded_before: "%{",
             expanded_after: "}",
             children: [
               %{kind: "atom", content: "{1, 2} => true", children: nil}
             ]
           } = plaintext_tree(%{{1, 2} => true})
  end

  defmodule User do
    defstruct [:email]
  end

  test "renders structs as nodes with children" do
    assert %{
             kind: "struct",
             content: "%Kino.TreeTest.User{...}",
             expanded_before: "%Kino.TreeTest.User{",
             expanded_after: "}",
             children: [
               %{kind: "binary", content: ~s(email: "user@example.com"), children: nil}
             ]
           } = plaintext_tree(%User{email: "user@example.com"})
  end

  test "uses special handling for regexes" do
    assert %{kind: "regex", content: "~r/foobar/", children: nil} = plaintext_tree(~r/foobar/)
    assert %{kind: "regex", content: "~r//", children: nil} = plaintext_tree(%Regex{})
  end

  test "uses the Inspect protocol for structs that implement it" do
    assert %{kind: "struct", content: "~D[2022-01-01]", children: nil} =
             plaintext_tree(Date.new!(2022, 1, 1))
  end

  test "renders other terms as string nodes using Inspect protocol" do
    assert %{kind: "other", content: "#PID<" <> _rest, children: nil} = plaintext_tree(self())
  end

  test "renders empty containers as leaf nodes" do
    assert %{content: "[]", children: nil} = plaintext_tree([])
    assert %{content: "{}", children: nil} = plaintext_tree({})
    assert %{content: "%{}", children: nil} = plaintext_tree(%{})
  end

  test "adds colors" do
    assert %{content: [%{text: "nil", color: "var(--ansi-color-magenta)"}]} = tree(nil)
    assert %{content: [%{text: "true", color: "var(--ansi-color-magenta)"}]} = tree(true)
    assert %{content: [%{text: "false", color: "var(--ansi-color-magenta)"}]} = tree(false)
    assert %{content: [%{text: ":atom", color: "var(--ansi-color-blue)"}]} = tree(:atom)
    assert %{content: [%{text: "1", color: "var(--ansi-color-blue)"}]} = tree(1)
    assert %{content: [%{text: "1.0", color: "var(--ansi-color-blue)"}]} = tree(1.0)
    assert %{content: [%{text: ~s("text"), color: "var(--ansi-color-green)"}]} = tree("text")
    assert %{content: [%{text: "~r/foobar/", color: "var(--ansi-color-red)"}]} = tree(~r/foobar/)
  end

  test "uses separate colors for keys and values" do
    assert %{
             content: [%{text: "[...]", color: nil}],
             expanded_before: [%{text: "[", color: nil}],
             expanded_after: [%{text: "]", color: nil}],
             children: [
               %{
                 content: [
                   %{text: "foo:", color: "var(--ansi-color-blue)"},
                   %{text: " ", color: nil},
                   %{text: "true", color: "var(--ansi-color-magenta)"}
                 ],
                 children: nil
               }
             ]
           } = tree(foo: true)
  end

  defp tree(input) do
    %Kino.Layout{
      type: :grid,
      items: [%Kino.JS{ref: ref}]
    } = Kino.Tree.new(input)

    send(Kino.JS.DataStore, {:connect, self(), %{origin: "client:#{inspect(self())}", ref: ref}})
    assert_receive {:connect_reply, data, %{ref: ^ref}}
    data
  end

  # Convert all content to strings for simpler assertions.
  defp plaintext_tree(input) do
    input |> tree() |> plaintext()
  end

  defp plaintext(nil) do
    nil
  end

  defp plaintext(list) when is_list(list) do
    Enum.map(list, &plaintext/1)
  end

  defp plaintext(%{content: content, children: nil} = node) do
    %{node | content: text_of(content)}
  end

  defp plaintext(
         %{
           content: content,
           children: children,
           expanded_before: expanded_before,
           expanded_after: expanded_after
         } = node
       ) do
    %{
      node
      | content: text_of(content),
        children: Enum.map(children, &plaintext/1),
        expanded_before: text_of(expanded_before),
        expanded_after: text_of(expanded_after)
    }
  end

  defp text_of(list) when is_list(list) do
    list |> Enum.map(& &1.text) |> Enum.join()
  end
end
