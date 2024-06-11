defmodule Kino.DataTable.Formatter do
  def format(:__header__, value) do
    string =
      value
      |> to_string()
      |> String.capitalize()
      |> String.replace("_", " ")

    {:ok, string}
  end

  def format(_key, value) when is_integer(value) do
    {:ok, "__#{value}__"}
  end

  def format(_key, _value) do
    :default
  end

end