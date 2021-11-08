defmodule Kino.FrameTest do
  use ExUnit.Case, async: true

  test "render/2 formats the givne value into output and sends to the client" do
    widget = Kino.Frame.new()

    connect_self(widget)

    Kino.Frame.render(widget, 1)
    assert_receive {:render, %{output: {:text, "\e[34m1\e[0m"}}}

    Kino.Frame.render(widget, Kino.Markdown.new("_hey_"))
    assert_receive {:render, %{output: {:markdown, "_hey_"}}}
  end

  test "periodically/4 evaluates the given callback in background until stopped" do
    widget = Kino.Frame.new()

    connect_self(widget)

    Kino.Frame.periodically(widget, 1, 1, fn n ->
      if n < 3 do
        Kino.Frame.render(widget, n)
        {:cont, n + 1}
      else
        :halt
      end
    end)

    assert_receive {:render, %{output: {:text, "\e[34m1\e[0m"}}}
    assert_receive {:render, %{output: {:text, "\e[34m2\e[0m"}}}
    refute_receive {:render, _}, 5
  end

  test "terminates as soon as the parent process terminates" do
    root = self()

    parent =
      spawn_link(fn ->
        widget = Kino.Frame.new()
        send(root, {:widget, widget})

        receive do
          :stop -> :ok
        end
      end)

    widget =
      receive do
        {:widget, widget} -> widget
      end

    ref = Process.monitor(widget.pid)
    send(parent, :stop)
    assert_receive {:DOWN, ^ref, :process, _, _}
  end

  defp connect_self(widget) do
    send(widget.pid, {:connect, self()})
    assert_receive {:connect_reply, %{}}
  end
end
