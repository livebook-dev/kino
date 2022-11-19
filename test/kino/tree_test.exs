defmodule Kino.TreeTest do
  use Kino.LivebookCase, async: true

  test "renders strings as string nodes" do
    assert %{content: ~s("some string"), children: nil} = plaintext_tree("some string")
  end

  test "renders atoms as nodes with inspected value" do
    assert %{content: ":foo", children: nil} = plaintext_tree(:foo)
    assert %{content: ~s(:"I need quotes"), children: nil} = plaintext_tree(:"I need quotes")
    assert %{content: "SomeModule", children: nil} = plaintext_tree(SomeModule)
  end

  test "renders numbers as nodes with inspected value" do
    assert %{content: "100", children: nil} = plaintext_tree(100)
    assert %{content: "100.0", children: nil} = plaintext_tree(100.0)
  end

  test "renders tuples as nodes with children" do
    assert %{
             content: "{...}",
             expanded: %{prefix: "{", suffix: "}"},
             children: [
               %{content: "1", children: nil}
             ]
           } = plaintext_tree({1})
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
           } = plaintext_tree({{1}})
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
           } = plaintext_tree({1, {:x, :y}, :three})
  end

  test "renders lists as nodes with children" do
    assert %{
             content: "[...]",
             expanded: %{prefix: "[", suffix: "]"},
             children: [
               %{content: "1", children: nil}
             ]
           } = plaintext_tree([1])
  end

  test "renders keywords as nodes with key-value children" do
    assert %{
             content: "[...]",
             expanded: %{prefix: "[", suffix: "]"},
             children: [
               %{content: "foo: :bar", children: nil}
             ]
           } = plaintext_tree(foo: :bar)
  end

  test "renders maps as nodes with key-value children" do
    assert %{
             content: "%{...}",
             expanded: %{prefix: "%{", suffix: "}"},
             children: [
               %{content: "foo: :bar", children: nil}
             ]
           } = plaintext_tree(%{foo: :bar})
  end

  test "uses the arrow for non-atom keys" do
    assert %{
             content: "%{...}",
             expanded: %{prefix: "%{", suffix: "}"},
             children: [
               %{content: ~s("foo" => "bar"), children: nil}
             ]
           } = plaintext_tree(%{"foo" => "bar"})
  end

  test "sorts maps by key" do
    assert %{
             content: "%{...}",
             expanded: %{prefix: "%{", suffix: "}"},
             children: [
               %{content: "bar: :baz,", children: nil},
               %{content: "foo: :oof", children: nil}
             ]
           } = plaintext_tree(%{foo: :oof, bar: :baz})
  end

  test "uses Inspect protocol for compound keys" do
    assert %{
             content: "%{...}",
             expanded: %{prefix: "%{", suffix: "}"},
             children: [
               %{content: "{1, 2} => true", children: nil}
             ]
           } = plaintext_tree(%{{1, 2} => true})
  end

  defmodule User do
    defstruct [:email]
  end

  test "renders structs as nodes with children" do
    assert %{
             content: "%Kino.TreeTest.User{...}",
             expanded: %{prefix: "%Kino.TreeTest.User{", suffix: "}"},
             children: [
               %{content: ~s(email: "user@example.com"), children: nil}
             ]
           } = plaintext_tree(%User{email: "user@example.com"})
  end

  test "uses special handling for regexes" do
    assert %{content: "~r/foobar/", children: nil} = plaintext_tree(~r/foobar/)
    assert %{content: "~r//", children: nil} = plaintext_tree(%Regex{})
  end

  test "uses the Inspect protocol for structs that implement it" do
    assert %{content: "~D[2022-01-01]", children: nil} = plaintext_tree(Date.new!(2022, 1, 1))
  end

  test "renders other terms as string nodes using Inspect protocol" do
    assert %{content: "#PID<" <> _rest, children: nil} = plaintext_tree(self())
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
             expanded: %{prefix: [%{text: "[", color: nil}], suffix: [%{text: "]", color: nil}]},
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
    %Kino.Layout{type: :grid, outputs: [js: %{js_view: %{ref: ref}}]} = Kino.Tree.new(input)
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

  defp plaintext(
         %{
           content: content,
           children: children,
           expanded: %{prefix: prefix, suffix: suffix} = expanded
         } = node
       ) do
    %{
      node
      | content: text_of(content),
        children: Enum.map(children, &plaintext/1),
        expanded: %{expanded | prefix: text_of(prefix), suffix: text_of(suffix)}
    }
  end

  defp plaintext(%{content: content, children: nil} = node) do
    %{node | content: text_of(content)}
  end

  defp text_of(list) when is_list(list) do
    list |> Enum.map(& &1.text) |> Enum.join()
  end
end
