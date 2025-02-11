defmodule Kino.TextTest do
  use Kino.LivebookCase, async: true

  describe "new/1" do
    test "outputs plain text" do
      "Hello!" |> Kino.Text.new() |> Kino.render()
      assert_output(%{type: :plain_text, text: "Hello!", chunk: false, style: []})

      "Hello!" |> Kino.Text.new(terminal: false) |> Kino.render()
      assert_output(%{type: :plain_text, text: "Hello!", chunk: false, style: []})

      "Hello!" |> Kino.Text.new(style: [font_weight: 300]) |> Kino.render()
      assert_output(%{type: :plain_text, text: "Hello!", chunk: false, style: [font_weight: 300]})
    end

    test "validates style" do
      assert_raise ArgumentError, ":style must be a keyword list", fn ->
        Kino.Text.new("Hello!", style: %{font_weight: 300})
      end

      assert_raise ArgumentError, ":style not supported when terminal: true", fn ->
        Kino.Text.new("Hello!", style: [font_weight: 300], terminal: true)
      end

      assert_raise ArgumentError, "invalid CSS property value for :font_weight", fn ->
        Kino.Text.new("Hello!", style: [font_weight: "300;color"])
      end
    end

    test "outputs terminal text" do
      "Hello!" |> Kino.Text.new(terminal: true) |> Kino.render()
      assert_output(%{type: :terminal_text, text: "Hello!", chunk: false})
    end
  end
end
