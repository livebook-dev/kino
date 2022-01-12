defmodule Kino.FrameTest do
  use Kino.LivebookCase, async: true

  test "render/2 formats the given value into output and sends as :replace frame" do
    widget = Kino.Frame.new()

    Kino.Frame.render(widget, 1)
    assert_output({:frame, [{:text, "\e[34m1\e[0m"}], %{type: :replace}})

    Kino.Frame.render(widget, Kino.Markdown.new("_hey_"))
    assert_output({:frame, [{:markdown, "_hey_"}], %{type: :replace}})
  end

  test "append/2 formats the given value into output and sends as :append frame" do
    widget = Kino.Frame.new()

    Kino.Frame.append(widget, 1)
    assert_output({:frame, [{:text, "\e[34m1\e[0m"}], %{type: :append}})
  end

  test "periodically/4 evaluates the given callback in background until stopped" do
    widget = Kino.Frame.new()

    parent = self()

    Kino.Frame.periodically(widget, 1, 1, fn n ->
      if n < 3 do
        send(parent, {:iteration, n})
        {:cont, n + 1}
      else
        :halt
      end
    end)

    assert_receive {:iteration, 1}
    assert_receive {:iteration, 2}
    refute_receive {:iteration, 3}, 5
  end
end
