defmodule Kino.RemoteExecutionCellTest do
  use ExUnit.Case, async: true

  import Kino.Test

  alias Kino.RemoteExecutionCell
  alias Kino.AttributeStore

  setup :configure_livebook_bridge

  @fields %{
    "assign_to" => "",
    "code" => ":ok",
    "node" => "name@node",
    "cookie" => "node-cookie",
    "use_cookie_secret" => false,
    "use_node_secret" => false,
    "node_secret" => "",
    "cookie_secret" => ""
  }

  test "returns the defaults when starting fresh with no data" do
    {_kino, source} = start_smart_cell!(RemoteExecutionCell, %{})

    assert source == ""
  end

  test "from saved attrs" do
    {_kino, source} = start_smart_cell!(RemoteExecutionCell, @fields)

    assert source == """
           require Kino.RPC
           node = :name@node
           Node.set_cookie(node, :"node-cookie")
           Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
           """
  end

  test "from saved attrs with result" do
    attrs = %{@fields | "assign_to" => "result"}
    {_kino, source} = start_smart_cell!(RemoteExecutionCell, attrs)

    assert source == """
           require Kino.RPC
           node = :name@node
           Node.set_cookie(node, :"node-cookie")
           result = Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
           """
  end

  test "from saved attrs with cookie as secret" do
    attrs = %{@fields | "use_cookie_secret" => true, "cookie_secret" => "COOKIE_SECRET"}
    {_kino, source} = start_smart_cell!(RemoteExecutionCell, attrs)

    assert source == """
           require Kino.RPC
           node = :name@node
           Node.set_cookie(node, String.to_atom(System.fetch_env!("LB_COOKIE_SECRET")))
           Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
           """
  end

  test "from saved attrs with cookie as input" do
    attrs = %{@fields | "use_cookie_secret" => false, "cookie" => "cookie-value"}
    {_kino, source} = start_smart_cell!(RemoteExecutionCell, attrs)

    assert source == """
           require Kino.RPC
           node = :name@node
           Node.set_cookie(node, :"cookie-value")
           Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
           """
  end

  describe "code generation" do
    test "do not generate code when there's no node" do
      attrs = %{@fields | "node" => ""}
      assert RemoteExecutionCell.to_source(attrs) == ""
    end

    test "do not generate code when there's no cookie" do
      attrs = %{@fields | "cookie" => ""}
      assert RemoteExecutionCell.to_source(attrs) == ""
    end

    test "do not generate code when there's no code" do
      attrs = %{@fields | "code" => ""}
      assert RemoteExecutionCell.to_source(attrs) == ""
    end

    test "generates an erpc call when there's valid code" do
      assert RemoteExecutionCell.to_source(@fields) == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """

      code = %{@fields | "code" => "1 + 1"}

      assert RemoteExecutionCell.to_source(code) == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             Kino.RPC.eval_string(node, ~S"1 + 1", file: __ENV__.file)\
             """

      code = %{@fields | "code" => "1 == 1"}

      assert RemoteExecutionCell.to_source(code) == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             Kino.RPC.eval_string(node, ~S"1 == 1", file: __ENV__.file)\
             """

      code = %{@fields | "code" => "a = 1\na + a"}

      assert RemoteExecutionCell.to_source(code) == ~s'''
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, :"node-cookie")

             Kino.RPC.eval_string(
               node,
               ~S"""
               a = 1
               a + a
               """,
               file: __ENV__.file
             )\
             '''

      code = %{@fields | "code" => ~S/"Number #{1}"/}

      assert RemoteExecutionCell.to_source(code) ==
               ~S'''
               require Kino.RPC
               node = :name@node
               Node.set_cookie(node, :"node-cookie")
               Kino.RPC.eval_string(node, ~S"\"Number #{1}\"", file: __ENV__.file)
               '''
               |> String.replace_trailing("\n", "")

      code = %{@fields | "code" => ~S/"Number #{1}"/ <> "\n:ok"}

      assert RemoteExecutionCell.to_source(code) ==
               ~S'''
               require Kino.RPC
               node = :name@node
               Node.set_cookie(node, :"node-cookie")

               Kino.RPC.eval_string(
                 node,
                 ~S"""
                 "Number #{1}"
                 :ok
                 """,
                 file: __ENV__.file
               )
               '''
               |> String.replace_trailing("\n", "")
    end

    test "assign to a variable" do
      attrs = %{@fields | "assign_to" => "result"}

      assert RemoteExecutionCell.to_source(attrs) == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             result = Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "do not assign to an invalid variable" do
      attrs = %{@fields | "assign_to" => "invalid result"}

      assert RemoteExecutionCell.to_source(attrs) == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "cookie value from secret" do
      attrs = %{@fields | "use_cookie_secret" => true, "cookie_secret" => "COOKIE_SECRET"}

      assert RemoteExecutionCell.to_source(attrs) == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, String.to_atom(System.fetch_env!("LB_COOKIE_SECRET")))
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "do not generate code for an invalid cookie secret" do
      attrs = %{@fields | "use_cookie_secret" => true, "cookie_secret" => ""}
      assert RemoteExecutionCell.to_source(attrs) == ""
    end

    test "node name from secret" do
      attrs = %{@fields | "use_node_secret" => true, "node_secret" => "NODE_SECRET"}

      assert RemoteExecutionCell.to_source(attrs) == """
             require Kino.RPC
             node = String.to_atom(System.fetch_env!("LB_NODE_SECRET"))
             Node.set_cookie(node, :"node-cookie")
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "do not generate code for an invalid node secret" do
      attrs = %{@fields | "use_node_secret" => true, "node_secret" => ""}
      assert RemoteExecutionCell.to_source(attrs) == ""
    end

    test "node and cookie from secrets" do
      attrs = %{
        @fields
        | "use_node_secret" => true,
          "node_secret" => "NODE_SECRET",
          "use_cookie_secret" => true,
          "cookie_secret" => "COOKIE_SECRET"
      }

      assert RemoteExecutionCell.to_source(attrs) == """
             require Kino.RPC
             node = String.to_atom(System.fetch_env!("LB_NODE_SECRET"))
             Node.set_cookie(node, String.to_atom(System.fetch_env!("LB_COOKIE_SECRET")))
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end
  end

  defmodule Global do
    use ExUnit.Case, async: false

    setup do
      AttributeStore.put_attribute({Kino.RemoteExecutionCell, :node}, {"name@node@global", nil})

      AttributeStore.put_attribute(
        {Kino.RemoteExecutionCell, :cookie},
        {"node-cookie-global", nil}
      )

      :ok
    end

    test "from stored attrs" do
      {_kino, source} = start_smart_cell!(RemoteExecutionCell, %{})

      assert source == """
             require Kino.RPC
             node = :name@node@global
             Node.set_cookie(node, :"node-cookie-global")
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "from stored attrs with cookie as a secret" do
      AttributeStore.put_attribute(
        {Kino.RemoteExecutionCell, :cookie},
        {nil, "COOKIE_SECRET_GLOBAL"}
      )

      {_kino, source} = start_smart_cell!(RemoteExecutionCell, %{})

      assert source == """
             require Kino.RPC
             node = :name@node@global
             Node.set_cookie(node, String.to_atom(System.fetch_env!("LB_COOKIE_SECRET_GLOBAL")))
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "from stored attrs with node as a secret" do
      AttributeStore.put_attribute(
        {Kino.RemoteExecutionCell, :node},
        {nil, "NODE_SECRET_GLOBAL"}
      )

      {_kino, source} = start_smart_cell!(RemoteExecutionCell, %{})

      assert source == """
             require Kino.RPC
             node = String.to_atom(System.fetch_env!("LB_NODE_SECRET_GLOBAL"))
             Node.set_cookie(node, :"node-cookie-global")
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "init attrs precedes stored attrs" do
      {_kino, source} = start_smart_cell!(RemoteExecutionCell, %{"node" => "name@node@attrs"})

      assert source == """
             require Kino.RPC
             node = :name@node@attrs
             Node.set_cookie(node, :"node-cookie-global")
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "stored attrs always come from the most recent edited cell" do
      {kino, _source} = start_smart_cell!(RemoteExecutionCell, %{})
      push_event(kino, "update_field", %{"field" => "node", "value" => "edited@node@name"})
      assert_receive {:runtime_smart_cell_update, _, _, _, _}

      {_kino, source} = start_smart_cell!(RemoteExecutionCell, %{})

      assert source == """
             require Kino.RPC
             node = :edited@node@name
             Node.set_cookie(node, :"node-cookie-global")
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end
  end
end
