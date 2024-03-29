defmodule Kino.OutputTest do
  use ExUnit.Case, async: false

  describe "inspect/1" do
    test "respects global inspect configuration" do
      Kino.Config.configure(inspect: [limit: 1, syntax_colors: []])

      list = Enum.to_list(1..100)
      assert Kino.Output.inspect(list) == %{type: :terminal_text, text: "[1, ...]", chunk: false}

      Application.delete_env(:kino, :inspect)
    end
  end
end
