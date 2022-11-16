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
    Kino.JS.new(__MODULE__, to_node(data))
  end

  defp to_node(string) when is_binary(string) do
    %{type: "string", value: string}
  end

  defp to_node(atom) when is_atom(atom) do
    %{type: "atom", value: Atom.to_string(atom)}
  end

  defp to_node(integer) when is_integer(integer) do
    %{type: "integer", value: integer}
  end

  defp to_node(float) when is_float(float) do
    %{type: "float", value: float}
  end

  defp to_node(tuple) when is_tuple(tuple) do
    children = tuple |> Tuple.to_list() |> Enum.map(&to_node/1)
    %{type: "tuple", value: nil, children: children}
  end

  defp to_node(list) when is_list(list) do
    if Keyword.keyword?(list) do
      children = Enum.map(list, fn {key, value} -> to_key_value_node(key, value) end)
      %{type: "list", value: nil, children: children}
    else
      children = Enum.map(list, &to_node/1)
      %{type: "list", value: nil, children: children}
    end
  end

  defp to_node(%module{} = struct) when is_struct(struct) do
    children =
      struct
      |> Map.from_struct()
      |> Enum.map(fn {key, value} -> to_key_value_node(key, value) end)

    %{type: "struct", value: Atom.to_string(module), children: children}
  end

  defp to_node(map) when is_map(map) do
    children =
      map
      |> Enum.sort_by(fn {key, _value} -> inspect(key) end)
      |> Enum.map(fn {key, value} -> to_key_value_node(key, value) end)

    %{type: "map", value: nil, children: children}
  end

  defp to_node(other) do
    %{type: "string", value: inspect(other)}
  end

  defp to_key_value_node(key, value) do
    simple_key =
      if is_binary(key) or is_atom(key) or is_number(key) do
        to_node(key)
      else
        %{type: "compoundkey", value: inspect(key, width: :infinity)}
      end

    value |> to_node() |> Map.put(:key, simple_key)
  end
end
