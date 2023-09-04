defmodule Kino.RemoteCellTest do
  use ExUnit.Case, async: true

  import Kino.Test

  alias Kino.RemoteCell

  setup :configure_livebook_bridge

  @fields %{
    "node" => "name@node",
    "cookie" => "node-cookie",
    "assign_to" => "",
    "code" => ":ok"
  }

  test "returns the defaults when starting fresh with no data" do
    {_kino, source} = start_smart_cell!(RemoteCell, %{})

    assert source == ""
  end

  test "from saved attrs" do
    {_kino, source} = start_smart_cell!(RemoteCell, @fields)

    assert source == """
           node = :name@node
           Node.set_cookie(node, :"node-cookie")
           :erpc.call(node, fn -> :ok end)\
           """
  end

  test "from saved attrs with result" do
    attrs = %{@fields | "assign_to" => "result"}
    {_kino, source} = start_smart_cell!(RemoteCell, attrs)

    assert source == """
           node = :name@node
           Node.set_cookie(node, :"node-cookie")
           result = :erpc.call(node, fn -> :ok end)\
           """
  end

  describe "code generation" do
    test "do not generate code when there's no node" do
      attrs = %{@fields | "node" => ""}
      assert RemoteCell.to_source(attrs) == ""
    end

    test "do not generate code when there's no cookie" do
      attrs = %{@fields | "cookie" => ""}
      assert RemoteCell.to_source(attrs) == ""
    end

    test "do not generate code when there's no code" do
      attrs = %{@fields | "code" => ""}
      assert RemoteCell.to_source(attrs) == ""
    end

    test "emites Code.string_to_quoted! when the code is invalid" do
      attrs = %{@fields | "code" => "1 + "}

      assert RemoteCell.to_source(attrs) == """
             # Invalid code for RPC, reproducing the error below
             Code.string_to_quoted!("1 + ")\
             """
    end

    test "generates an erpc call when there's valid code" do
      code1 = %{@fields | "code" => "1 + 1"}
      code2 = %{@fields | "code" => "1 == 1"}
      code3 = %{@fields | "code" => "a = 1\na + a"}

      assert RemoteCell.to_source(@fields) == """
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             :erpc.call(node, fn -> :ok end)\
             """

      assert RemoteCell.to_source(code1) == """
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             :erpc.call(node, fn -> 1 + 1 end)\
             """

      assert RemoteCell.to_source(code2) == """
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             :erpc.call(node, fn -> 1 == 1 end)\
             """

      assert RemoteCell.to_source(code3) == """
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             
             :erpc.call(node, fn ->
               a = 1
               a + a
             end)\
             """
    end

    test "assign to a variable" do
      attrs = %{@fields | "assign_to" => "result"}

      assert RemoteCell.to_source(attrs) == """
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             result = :erpc.call(node, fn -> :ok end)\
             """
    end

    test "do not assign to an invalid variable" do
      attrs = %{@fields | "assign_to" => "invalid result"}

      assert RemoteCell.to_source(attrs) == """
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             :erpc.call(node, fn -> :ok end)\
             """
    end
  end
end
