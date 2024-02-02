defmodule Kino.FrameTest do
  use Kino.LivebookCase, async: true

  test "render/2 formats the given value into output and sends as :replace frame" do
    frame = Kino.Frame.new()

    Kino.Frame.render(frame, 1)

    assert_output(%{
      type: :frame_update,
      update: {:replace, [%{type: :terminal_text, text: "\e[34m1\e[0m"}]}
    })

    Kino.Frame.render(frame, Kino.Markdown.new("_hey_"))

    assert_output(%{
      type: :frame_update,
      update: {:replace, [%{type: :markdown, text: "_hey_", chunk: false}]}
    })
  end

  test "render/2 sends output to a specific client when the :to is given" do
    frame = Kino.Frame.new()

    Kino.Frame.render(frame, 1, to: "client1")

    assert_output_to(
      "client1",
      %{type: :frame_update, update: {:replace, [%{type: :terminal_text, text: "\e[34m1\e[0m"}]}}
    )

    assert Kino.Frame.get_items(frame) == []
  end

  test "render/2 sends output directly to clients when :temporary is true" do
    frame = Kino.Frame.new()

    Kino.Frame.render(frame, 1, temporary: true)

    assert_output_to_clients(%{
      type: :frame_update,
      update: {:replace, [%{type: :terminal_text, text: "\e[34m1\e[0m"}]}
    })

    assert Kino.Frame.get_items(frame) == []
  end

  test "render/2 raises when :to and :temporary is disabled" do
    frame = Kino.Frame.new()

    assert_raise ArgumentError,
                 "direct updates sent via :to are never part of the frame history, disabling :temporary is not supported",
                 fn ->
                   Kino.Frame.render(frame, 1, to: "client1", temporary: false)
                 end
  end

  test "render/2 references rendered kino before the caller terminates" do
    frame = Kino.Frame.new()

    myself = self()

    Kino.async_listen([0], fn _i ->
      kino = Kino.HTML.new("Hello")
      send(myself, {:process, self(), kino.ref})
      Kino.Frame.render(frame, kino)
    end)

    assert_receive {:process, pid, kino_ref}
    ref = Process.monitor(pid)

    frame_pid = frame.pid

    assert_receive {:livebook_reference_object, ^kino_ref, ^pid}
    assert_receive {:DOWN, ^ref, :process, _object, _reason}
    # We should've already received the reference from the frame
    assert_received {:livebook_reference_object, ^kino_ref, ^frame_pid}
  end

  test "append/2 formats the given value into output and sends as :append frame" do
    frame = Kino.Frame.new()

    Kino.Frame.append(frame, 1)

    assert_output(%{
      type: :frame_update,
      update: {:append, [%{type: :terminal_text, text: "\e[34m1\e[0m"}]}
    })
  end

  test "Kino.Render.to_livebook/1 returns the current value for a nested frame" do
    frame = Kino.Frame.new()

    frame_inner = Kino.Frame.new()

    Kino.Frame.render(frame, frame_inner)

    assert %{
             type: :frame,
             outputs: [%{type: :frame, outputs: []}]
           } = Kino.Render.to_livebook(frame)

    Kino.Frame.render(frame_inner, 1)

    assert %{
             type: :frame,
             outputs: [%{type: :frame, outputs: [%{type: :terminal_text, text: "\e[34m1\e[0m"}]}]
           } = Kino.Render.to_livebook(frame)
  end
end
