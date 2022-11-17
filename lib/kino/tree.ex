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
  """

  use Kino.JS, assets_path: "lib/assets/tree"

  def new(data) do
    Kino.Layout.grid([Kino.JS.new(__MODULE__, to_node(data))], boxed: true)
  end

  defp to_node(string) when is_binary(string) do
    %{content: inspect(string), children: nil}
  end

  defp to_node(atom) when is_atom(atom) do
    %{content: inspect(atom), children: nil}
  end

  defp to_node(number) when is_number(number) do
    %{content: inspect(number), children: nil}
  end

  defp to_node(tuple) when is_tuple(tuple) do
    size = tuple_size(tuple)
    children = tuple |> Tuple.to_list() |> to_children(size)

    %{
      content: "{...}",
      children: children,
      expanded: %{prefix: "{", suffix: "}"}
    }
  end

  defp to_node(list) when is_list(list) do
    size = length(list)

    children =
      if Keyword.keyword?(list) do
        to_key_value_children(list, size)
      else
        to_children(list, size)
      end

    %{
      content: "[...]",
      children: children,
      expanded: %{prefix: "[", suffix: "]"}
    }
  end

  defp to_node(%Regex{} = regex) do
    %{content: inspect(regex), children: nil}
  end

  defp to_node(%module{} = struct) when is_struct(struct) do
    map = Map.from_struct(struct)
    size = map_size(map)
    children = to_key_value_children(map, size)

    %{
      content: "%#{inspect(module)}{...}",
      children: children,
      expanded: %{prefix: "%#{inspect(module)}{", suffix: "}"}
    }
  end

  defp to_node(map) when is_map(map) do
    size = map_size(map)
    children = to_key_value_children(map, size)

    %{
      content: "%{...}",
      children: children,
      expanded: %{prefix: "%{", suffix: "}"}
    }
  end

  defp to_node(other) do
    %{content: inspect(other), children: nil}
  end

  defp to_key_value_node({key, value}) do
    key_text =
      case inspect(key) do
        ":" <> name when is_atom(key) -> name <> ": "
        key -> key <> " => "
      end

    case to_node(value) do
      %{content: content, expanded: %{prefix: prefix} = expanded} = node ->
        %{node | content: key_text <> content, expanded: %{expanded | prefix: key_text <> prefix}}

      %{content: content} = node ->
        %{node | content: key_text <> content}
    end
  end

  defp to_children(items, container_size) do
    items |> Enum.map(&to_node/1) |> with_commas(container_size)
  end

  defp to_key_value_children(items, container_size) do
    items |> Enum.map(&to_key_value_node/1) |> with_commas(container_size)
  end

  defp with_commas(children, container_size) do
    children
    |> Enum.with_index()
    |> Enum.map(fn {node, index} ->
      comma = if index != container_size - 1, do: ",", else: ""

      case node do
        %{content: content, expanded: %{suffix: suffix} = expanded} = node ->
          %{node | content: content <> comma, expanded: %{expanded | suffix: suffix <> comma}}

        %{content: content} = node ->
          %{node | content: content <> comma}
      end
    end)
  end
end
