defmodule Kino.ScreenTest do
  use Kino.LivebookCase, async: true

  import Kino.Control

  defmodule MyScreen do
    def new(rendering_fun) do
      Kino.Screen.new(__MODULE__, rendering_fun)
    end

    def render(rendering_fun) do
      rendering_fun.()
    end
  end

  test "renders" do
    _frame = MyScreen.new(fn -> "hello" end)

    assert_output(%{
      type: :frame_update,
      update: {:replace, [%{type: :terminal_text, text: "\e[32m\"hello\"\e[0m"}]}
    })
  end

  test "renders user update events on control" do
    parent = self()
    button = button("hello")
    frame = MyScreen.new(fn -> control(button, parent) end)

    assert_output(%{type: :frame_update, update: {:replace, [%{type: :control}]}})
    {watcher, dyn_sup} = screen_tree(frame)

    # Verify a new user spawns a new workers
    click_button(button, "client1")
    assert_output_to("client1", %{type: :frame_update, update: {:replace, [%{type: :control}]}})

    assert [{_, user_screen, :worker, [Kino.Screen.Server]}] =
             DynamicSupervisor.which_children(dyn_sup)

    # Verify the user screen terminates when the client leaves
    ref = Process.monitor(user_screen)
    send(watcher, {:client_leave, "unknown_client1"})
    send(watcher, {:client_leave, "client1"})
    assert_receive {:DOWN, ^ref, :process, ^user_screen, _}
  end

  test "does not crash tree when user event cannot be processed/rendered" do
    ok_button = button("ok")
    fail_event_button = button("fail_event")
    fail_render_button = button("fail_render")

    frame =
      MyScreen.new(fn ->
        Kino.Layout.grid([
          Kino.Screen.control(ok_button, fn _, _ -> fn -> ok_button end end),
          Kino.Screen.control(fail_event_button, fn _, _ -> raise "oops" end),
          Kino.Screen.control(fail_render_button, fn _, _ -> fn -> raise "oops" end end)
        ])
      end)

    assert_output(%{type: :frame_update, update: {:replace, [%{type: :grid}]}})
    {watcher, _dyn_sup} = screen_tree(frame)

    assert ExUnit.CaptureLog.capture_log(fn ->
             click_button(fail_event_button, "client1")
             click_button(ok_button, "client1")
             assert_output_to("client1", %{type: :frame_update})
           end) =~ "** (RuntimeError) oops"

    assert Process.alive?(watcher)

    assert ExUnit.CaptureLog.capture_log(fn ->
             click_button(fail_render_button, "client2")
             click_button(ok_button, "client2")
             assert_output_to("client2", %{type: :frame_update})
           end) =~ "** (RuntimeError) oops"

    assert Process.alive?(watcher)
  end

  defp control(button, parent) do
    Kino.Screen.control(button, fn event, state ->
      send(parent, {:control, event})
      state
    end)
  end

  defp click_button(button, client) do
    info = %{origin: client}
    send(button.destination, {:event, button.ref, info})
  end

  defp screen_tree(frame) do
    # Fetch screen supervision tree
    assert_receive {:livebook_reference_object, sup, _}
                   when is_pid(sup) and sup != self() and sup != frame.pid

    [
      {Kino.Screen.Watcher, watcher, :worker, _},
      {DynamicSupervisor, dyn_sup, :supervisor, _}
    ] = Supervisor.which_children(sup)

    assert [] = DynamicSupervisor.which_children(dyn_sup)
    {watcher, dyn_sup}
  end
end
