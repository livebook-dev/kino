defmodule Kino.TextTest do
  use Kino.LivebookCase, async: true

  describe "new/1" do
    test "outputs plain text" do
      "Hello!" |> Kino.Text.new() |> Kino.render()
      assert_output({:plain_text, "Hello!", %{chunk: false}})

      "Hello!" |> Kino.Text.new(terminal: false) |> Kino.render()
      assert_output({:plain_text, "Hello!", %{chunk: false}})
    end

    test "outputs terminal text" do
      "Hello!" |> Kino.Text.new(terminal: true) |> Kino.render()
      assert_output({:terminal_text, "Hello!", %{chunk: false}})
    end
  end
end
