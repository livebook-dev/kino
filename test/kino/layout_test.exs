defmodule Kino.LayoutTest do
  use Kino.LivebookCase, async: true

  describe "tabs" do
    test "Kino.Render.to_livebook/1 returns the current value for a nested frame" do
      frame_inner = Kino.Frame.new()

      tabs = Kino.Layout.tabs(frame: frame_inner)

      assert %{
               type: :tabs,
               outputs: [%{type: :frame, outputs: []}]
             } = Kino.Render.to_livebook(tabs)

      Kino.Frame.render(frame_inner, 1)

      assert %{
               type: :tabs,
               outputs: [
                 %{type: :frame, outputs: [%{type: :terminal_text, text: "\e[34m1\e[0m"}]}
               ]
             } = Kino.Render.to_livebook(tabs)
    end
  end

  describe "grid" do
    test "Kino.Render.to_livebook/1 returns the current value for a nested frame" do
      frame_inner = Kino.Frame.new()

      grid = Kino.Layout.grid([frame_inner])

      assert %{
               type: :grid,
               outputs: [%{type: :frame, outputs: []}]
             } = Kino.Render.to_livebook(grid)

      Kino.Frame.render(frame_inner, 1)

      assert %{
               type: :grid,
               outputs: [
                 %{type: :frame, outputs: [%{type: :terminal_text, text: "\e[34m1\e[0m"}]}
               ]
             } = Kino.Render.to_livebook(grid)
    end
  end
end
