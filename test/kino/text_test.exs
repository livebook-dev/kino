defmodule Kino.TextTest do
  use Kino.LivebookCase, async: true

  describe "new/1" do
    test "outputs plain text" do
      "Hello!" |> Kino.Text.new() |> Kino.render()
      assert_output({:plain_text, "Hello!"})

      "Hello!" |> Kino.Text.new(terminal: false) |> Kino.render()
      assert_output({:plain_text, "Hello!"})
    end

    test "outputs terminal text" do
      "Hello!" |> Kino.Text.new(terminal: true) |> Kino.render()
      assert_output({:text, "Hello!"})
    end
  end
end
