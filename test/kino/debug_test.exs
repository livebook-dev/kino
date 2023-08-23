defmodule Kino.Debug.Test do
  use Kino.LivebookCase, async: true

  defmacrop call_dbg(ast) do
    quote do
      unquote(Kino.Debug.dbg(ast, [], __CALLER__))
    end
  end

  describe "dbg with a pipeline expression" do
    defp assert_dbg_pipeline_render() do
      assert_output(%{
        type: :grid,
        outputs: [
          %{type: :js, js_view: js_view},
          %{type: :frame, ref: frame_ref, outputs: [output]}
        ]
      })

      kino = %Kino.JS.Live{ref: js_view.ref, pid: js_view.pid}

      {kino, output, frame_ref}
    end

    test "initial render" do
      call_dbg(
        1..5
        |> Enum.filter(&(rem(&1, 2) == 0))
        |> Enum.map(&(&1 * 2))
        |> Enum.sum()
        |> Kernel.+(1)
      )

      {kino, output, _frame_ref} = assert_dbg_pipeline_render()

      assert output == %{type: :terminal_text, text: "\e[34m13\e[0m", chunk: false}

      %{
        dbg_line: dbg_line,
        call_count: 1,
        items: [
          %{id: 0, source: "1..5"},
          %{id: 1, source: "|> Enum.filter(&(rem(&1, 2) == 0))"},
          %{id: 2, source: "|> Enum.map(&(&1 * 2))"},
          %{id: 3, source: "|> Enum.sum()"},
          %{id: 4, source: "|> Kernel.+(1)"}
        ],
        selected_id: 4,
        error: nil,
        errored_id: nil,
        changed: false
      } = connect(kino)

      assert dbg_line == __ENV__.line - 28
    end

    test "updates result when a pipeline step is disabled" do
      call_dbg(
        1..5
        |> Enum.filter(&(rem(&1, 2) == 0))
        |> Enum.map(&(&1 * 2))
        |> Enum.sum()
        |> Kernel.+(1)
      )

      {kino, _output, frame_ref} = assert_dbg_pipeline_render()

      _ = connect(kino)

      push_event(kino, "update_enabled", %{"id" => 1, "enabled" => false})

      assert_broadcast_event(kino, "enabled_updated", %{
        "id" => 1,
        "enabled" => false,
        "selected_id" => 4,
        "changed" => true
      })

      assert_output(%{
        type: :frame_update,
        ref: ^frame_ref,
        update: {:replace, [%{type: :terminal_text, text: "\e[34m31\e[0m", chunk: false}]}
      })
    end

    test "updates result when a pipeline step is moved" do
      call_dbg(
        1..5
        |> Enum.filter(&(rem(&1, 2) == 0))
        |> Enum.map(&(&1 * 2))
        |> Enum.sum()
        |> Kernel.+(1)
      )

      {kino, _output, frame_ref} = assert_dbg_pipeline_render()

      _ = connect(kino)

      push_event(kino, "move_item", %{"id" => 1, "index" => 2})

      assert_broadcast_event(kino, "item_moved", %{
        "id" => 1,
        "index" => 2,
        "changed" => true
      })

      assert_output(%{
        type: :frame_update,
        ref: ^frame_ref,
        update: {:replace, [%{type: :terminal_text, text: "\e[34m31\e[0m", chunk: false}]}
      })
    end

    test "handles evaluation error" do
      call_dbg(
        1..5
        |> Enum.filter(&(rem(&1, 2) == 0))
        |> Enum.map(&(&1 * 2))
        |> Enum.sum()
        |> Kernel.+(1)
      )

      {kino, _output, frame_ref} = assert_dbg_pipeline_render()

      _ = connect(kino)
      push_event(kino, "move_item", %{"id" => 4, "index" => 1})

      assert_broadcast_event(kino, "set_errored", %{
        "id" => 4,
        "error" => "** (ArithmeticError) bad argument in arithmetic expression",
        "selected_id" => 0
      })

      assert_output(%{
        type: :frame_update,
        ref: ^frame_ref,
        update:
          {:replace, [%{type: :terminal_text, text: "\e[34m1\e[0m..\e[34m5\e[0m", chunk: false}]}
      })
    end

    test "groups multiple calls to the same dbg" do
      fun = fn ->
        call_dbg(
          1..5
          |> Enum.filter(&(rem(&1, 2) == 0))
          |> Enum.map(&(&1 * 2))
          |> Enum.sum()
          |> Kernel.+(1)
        )
      end

      for _ <- 1..5 do
        fun.()
      end

      {kino, _output, _frame_ref} = assert_dbg_pipeline_render()

      assert_broadcast_event(kino, "call_count_updated", %{"call_count" => 5})

      %{call_count: 5} = connect(kino)
    end
  end

  describe "dbg with a non-pipeline expression" do
    defp assert_dbg_default_render() do
      assert_output(%{type: :grid, outputs: [%{type: :js, js_view: js_view}, output]})
      kino = %Kino.JS.Live{ref: js_view.ref, pid: js_view.pid}
      {kino, output}
    end

    test "initial render" do
      call_dbg(Enum.sum(1..5))

      {kino, output} = assert_dbg_default_render()

      assert output == %{type: :terminal_text, text: "\e[34m15\e[0m", chunk: false}

      %{
        dbg_line: dbg_line,
        call_count: 1,
        source: "Enum.sum(1..5)"
      } = connect(kino)

      assert dbg_line == __ENV__.line - 12
    end

    test "groups multiple calls to the same dbg" do
      fun = fn ->
        call_dbg(Enum.sum(1..5))
      end

      for _ <- 1..5 do
        fun.()
      end

      {kino, _output} = assert_dbg_default_render()

      assert_broadcast_event(kino, "call_count_updated", %{"call_count" => 5})

      %{call_count: 5} = connect(kino)
    end
  end

  test "falls back to the default dbg implementation when outside livebook context" do
    # Capturing IO switches the group leader, so the function effectively
    # runs outside the livebook context
    assert ExUnit.CaptureIO.capture_io(fn -> call_dbg(:ok) end) =~ ":ok"
  end
end
