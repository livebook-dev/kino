defmodule Kino.TextTest do
  use Kino.LivebookCase, async: true

  describe "new/1" do
    test "outputs plain text" do
      "Hello!" |> Kino.Text.new() |> Kino.render()
      assert_output({:plain_text, "Hello!"})

      "Hello!" |> Kino.Text.new(console: false) |> Kino.render()
      assert_output({:plain_text, "Hello!"})
    end

    test "outputs console text" do
      [:red, "Hello!"]
      |> IO.ANSI.format()
      |> IO.iodata_to_binary()
      |> Kino.Text.new(console: true)
      |> Kino.render()

      assert_output({:text, "\e[31mHello!\e[0m"})
    end
  end
end
