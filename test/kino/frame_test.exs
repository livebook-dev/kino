defmodule Kino.FrameTest do
  use Kino.LivebookCase, async: true

  test "render/2 formats the given value into output and sends as :replace frame" do
    frame = Kino.Frame.new()

    Kino.Frame.render(frame, 1)
    assert_output({:frame, [{:text, "\e[34m1\e[0m"}], %{type: :replace}})

    Kino.Frame.render(frame, Kino.Markdown.new("_hey_"))
    assert_output({:frame, [{:markdown, "_hey_"}], %{type: :replace}})
  end

  test "render/2 sends output to a specific client when the :to is given" do
    frame = Kino.Frame.new()

    Kino.Frame.render(frame, 1, to: "client1")
    assert_output_to("client1", {:frame, [{:text, "\e[34m1\e[0m"}], %{type: :replace}})

    assert Kino.Frame.get_outputs(frame) == []
  end

  test "render/2 sends output directly to clients when :temporary is true" do
    frame = Kino.Frame.new()

    Kino.Frame.render(frame, 1, temporary: true)
    assert_output_to_clients({:frame, [{:text, "\e[34m1\e[0m"}], %{type: :replace}})

    assert Kino.Frame.get_outputs(frame) == []
  end

  test "render/2 raises when :to and :temporary is disabled" do
    frame = Kino.Frame.new()

    assert_raise ArgumentError,
                 "direct updates sent via :to are never part of the frame history, disabling :temporary is not supported",
                 fn ->
                   Kino.Frame.render(frame, 1, to: "client1", temporary: false)
                 end
  end

  test "append/2 formats the given value into output and sends as :append frame" do
    frame = Kino.Frame.new()

    Kino.Frame.append(frame, 1)
    assert_output({:frame, [{:text, "\e[34m1\e[0m"}], %{type: :append}})
  end

  test "periodically/4 evaluates the given callback in background until stopped" do
    frame = Kino.Frame.new()

    parent = self()

    Kino.Frame.periodically(frame, 1, 1, fn n ->
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
