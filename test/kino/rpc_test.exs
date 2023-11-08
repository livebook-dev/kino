defmodule Kino.RPCTest do
  use ExUnit.Case, async: true

  require Kino.RPC

  test "captures caller binding" do
    x = 1
    y = 1

    assert Kino.RPC.eval_string(node(), "x + y") == 2

    assert Kino.RPC.eval_string(node(), "{x, binding()}") == {1, [x: 1]}
  end

  test "propagates errors" do
    assert_raise ArgumentError, "error", fn ->
      Kino.RPC.eval_string(node(), """
      raise ArgumentError, "error"
      """)
    end

    assert_raise TokenMissingError, fn ->
      Kino.RPC.eval_string(node(), "1 +")
    end

    assert ExUnit.CaptureIO.capture_io(:stderr, fn ->
             assert_raise CompileError, fn ->
               Kino.RPC.eval_string(node(), "unknown + 1")
             end
           end) =~ ~s/undefined variable "unknown"/
  end
end
