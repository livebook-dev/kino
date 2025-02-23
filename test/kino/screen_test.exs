defmodule Kino.ScreenTest do
  use Kino.LivebookCase, async: true

  import Kino.Control

  defmodule MyScreen do
    def new(state) do
      Kino.Screen.new(__MODULE__, state)
    end

    def render(state) do
      state.()
    end
  end

  defp control(button, parent) do
    Kino.Screen.control(button, fn event, state ->
      send(parent, {:control, event})
      state
    end)
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

    # Click the button
    info = %{origin: "client1"}
    send(button.destination, {:event, button.ref, info})

    assert_output_to("client1", %{
      type: :frame_update,
      update: {:replace, [%{type: :control}]}
    })

    assert [{_, user_screen, :worker, [Kino.Screen.Server]}] =
             DynamicSupervisor.which_children(dyn_sup)

    # Verify the user screen terminates when the client leaves
    ref = Process.monitor(user_screen)
    send(watcher, {:client_leave, "unknown_client1"})
    send(watcher, {:client_leave, "client1"})
    assert_receive {:DOWN, ^ref, :process, ^user_screen, _}
  end

  test "does not crash tree when user event cannot be processed/rendered" do
    button = button("hello")

    frame =
      MyScreen.new(fn ->
        Kino.Screen.control(button, fn
          %{type: :succeed}, _ -> fn -> button end
          %{type: :fail_event}, _ -> raise "oops"
          %{type: :fail_render}, _ -> fn -> raise "oops" end
        end)
      end)

    assert_output(%{type: :frame_update, update: {:replace, [%{type: :control}]}})
    {watcher, _dyn_sup} = screen_tree(frame)

    assert ExUnit.CaptureLog.capture_log(fn ->
             # Click the button and make it fail
             info = %{origin: "client1", type: :fail_event}
             send(button.destination, {:event, button.ref, info})

             # Click the button and make it succeed as a sync mechanism
             info = %{origin: "client1", type: :succeed}
             send(button.destination, {:event, button.ref, info})
             assert_output_to("client1", %{type: :frame_update})
           end) =~ "** (RuntimeError) oops"

    assert Process.alive?(watcher)

    assert ExUnit.CaptureLog.capture_log(fn ->
             # Click the button and make it fail
             info = %{origin: "client1", type: :fail_render}
             send(button.destination, {:event, button.ref, info})

             # Click the button and make it succeed as a sync mechanism
             info = %{origin: "client1", type: :succeed}
             send(button.destination, {:event, button.ref, info})
             assert_output_to("client1", %{type: :frame_update})
           end) =~ "** (RuntimeError) oops"

    assert Process.alive?(watcher)
  end
end
