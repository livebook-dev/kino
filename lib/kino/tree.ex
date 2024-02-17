defmodule Kino.Tree do
  @moduledoc """
  A kino for interactively viewing nested data as a tree view.

  The data can be any term.

  ## Examples

      data = %{
        id: 1,
        email: "user@example.com",
        inserted_at: ~U[2022-01-01T10:00:00Z],
        addresses: [
          %{
            country: "pl",
            city: "Kraków",
            street: "Karmelicka",
            zip: "00123"
          }
        ]
      }

      Kino.Tree.new(data)

  The tree view is particularly useful when inspecting larger data
  structures:

      data = Process.info(self())
      Kino.Tree.new(data)

  """

  use Kino.JS, assets_path: "lib/assets/tree/build"

  @doc """
  Creates a new kino displaying the given data structure.
  """
  @spec new(term()) :: Kino.Layout.t()
  def new(data) do
    tree = to_node(data, [])
    kino = Kino.JS.new(__MODULE__, tree)
    Kino.Layout.grid([kino], boxed: true)
  end

  defp to_node(string, suffix) when is_binary(string) do
    %{kind: "binary", content: [green(inspect(string)) | suffix], children: nil}
  end

  defp to_node(atom, suffix) when is_atom(atom) do
    span =
      if atom in [nil, true, false] do
        magenta(inspect(atom))
      else
        blue(inspect(atom))
      end

    %{kind: "atom", content: [span | suffix], children: nil}
  end

  defp to_node(number, suffix) when is_number(number) do
    %{kind: "number", content: [blue(inspect(number)) | suffix], children: nil}
  end

  defp to_node({}, suffix) do
    %{kind: "tuple", content: [black("{}") | suffix], children: nil}
  end

  defp to_node(tuple, suffix) when is_tuple(tuple) do
    size = tuple_size(tuple)
    children = tuple |> Tuple.to_list() |> to_children(size)

    %{
      kind: "tuple",
      content: [black("{...}") | suffix],
      children: children,
      expanded_before: [black("{")],
      expanded_after: [black("}") | suffix]
    }
  end

  defp to_node([], suffix) do
    %{kind: "list", content: [black("[]") | suffix], children: nil}
  end

  defp to_node(list, suffix) when is_list(list) do
    size = length(list)

    children =
      if Keyword.keyword?(list) do
        to_key_value_children(list, size)
      else
        to_children(list, size)
      end

    %{
      kind: "list",
      content: [black("[...]") | suffix],
      children: children,
      expanded_before: [black("[")],
      expanded_after: [black("]") | suffix]
    }
  end

  defp to_node(%Regex{} = regex, suffix) do
    %{kind: "regex", content: [red(inspect(regex)) | suffix], children: nil}
  end

  defp to_node(%module{} = struct, suffix) when is_struct(struct) do
    if Inspect.impl_for(struct) != Inspect.Any do
      %{kind: "struct", content: [black(inspect(struct)) | suffix], children: nil}
    else
      map = Map.from_struct(struct)
      size = map_size(map)
      children = to_key_value_children(map, size)

      %{
        kind: "struct",
        content: [black("%"), blue(inspect(module)), black("{...}") | suffix],
        children: children,
        expanded_before: [black("%"), blue(inspect(module)), black("{")],
        expanded_after: [black("}") | suffix]
      }
    end
  end

  defp to_node(%{} = map, suffix) when map_size(map) == 0 do
    %{kind: "map", content: [black("%{}") | suffix], children: nil}
  end

  defp to_node(map, suffix) when is_map(map) do
    size = map_size(map)
    children = map |> Enum.sort() |> to_key_value_children(size)

    %{
      kind: "map",
      content: [black("%{...}") | suffix],
      children: children,
      expanded_before: [black("%{")],
      expanded_after: [black("}") | suffix]
    }
  end

  defp to_node(other, suffix) do
    %{kind: "other", content: [black(inspect(other)) | suffix], children: nil}
  end

  defp to_key_value_node({key, value}, suffix) do
    {key_span, sep_span} =
      case to_node(key, []) do
        %{content: [%{text: ":" <> name} = span]} when is_atom(key) ->
          {%{span | text: name <> ":"}, black(" ")}

        %{content: [span]} ->
          {%{span | text: inspect(key, width: :infinity)}, black(" => ")}
      end

    case to_node(value, suffix) do
      %{content: content, expanded_before: expanded_before} = node ->
        %{
          node
          | content: [key_span, sep_span | content],
            expanded_before: [key_span, sep_span | expanded_before]
        }

      %{content: content} = node ->
        %{node | content: [key_span, sep_span | content]}
    end
  end

  defp to_children(items, container_size) do
    Enum.with_index(items, fn item, index ->
      to_node(item, suffix(index, container_size))
    end)
  end

  defp to_key_value_children(items, container_size) do
    Enum.with_index(items, fn item, index ->
      to_key_value_node(item, suffix(index, container_size))
    end)
  end

  defp suffix(index, container_size) do
    if index != container_size - 1 do
      [black(",")]
    else
      []
    end
  end

  defp black(text), do: %{text: text, color: nil}
  defp red(text), do: %{text: text, color: "var(--ansi-color-red)"}
  defp green(text), do: %{text: text, color: "var(--ansi-color-green)"}
  defp blue(text), do: %{text: text, color: "var(--ansi-color-blue)"}
  defp magenta(text), do: %{text: text, color: "var(--ansi-color-magenta)"}
end
