defmodule Kino.RemoteExecutionCellTest do
  use ExUnit.Case, async: true

  import Kino.Test

  alias Kino.RemoteExecutionCell
  alias Kino.AttributeStore

  setup :configure_livebook_bridge

  @attrs %{
    "assign_to" => "",
    "code" => ":ok",
    "node_source" => "text",
    "node_text" => "name@node",
    "cookie_source" => "text",
    "cookie_text" => "node-cookie"
  }

  describe "initialization" do
    test "returns the defaults when starting fresh with no data" do
      {_kino, source} = start_smart_cell!(RemoteExecutionCell, %{})

      assert source == ""
    end

    test "from saved attrs" do
      {_kino, source} = start_smart_cell!(RemoteExecutionCell, @attrs)

      assert source == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "from saved attrs with result" do
      attrs = %{@attrs | "assign_to" => "result"}
      {_kino, source} = start_smart_cell!(RemoteExecutionCell, attrs)

      assert source == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             result = Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "from legacy saved attrs" do
      attrs = %{
        "assign_to" => "",
        "code" => ":ok",
        "use_node_secret" => false,
        "node" => "name@node",
        "use_cookie_secret" => true,
        "cookie_secret" => "COOKIE_SECRET"
      }

      {_kino, source} = start_smart_cell!(RemoteExecutionCell, attrs)

      assert source == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, String.to_atom(System.fetch_env!("LB_COOKIE_SECRET")))
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end
  end

  describe "code generation" do
    test "do not generate code when there's no node" do
      attrs = %{@attrs | "node_text" => ""}
      assert RemoteExecutionCell.to_source(attrs) == ""
    end

    test "do not generate code when there's no cookie" do
      attrs = %{@attrs | "cookie_text" => ""}
      assert RemoteExecutionCell.to_source(attrs) == ""
    end

    test "do not generate code when there's no code" do
      attrs = %{@attrs | "code" => ""}
      assert RemoteExecutionCell.to_source(attrs) == ""
    end

    test "generates an erpc call when there's valid code" do
      assert RemoteExecutionCell.to_source(@attrs) == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """

      code = %{@attrs | "code" => "1 + 1"}

      assert RemoteExecutionCell.to_source(code) == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             Kino.RPC.eval_string(node, ~S"1 + 1", file: __ENV__.file)\
             """

      code = %{@attrs | "code" => "a = 1\na + a"}

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

      code = %{@attrs | "code" => ~S/"Number #{1}"/}

      assert RemoteExecutionCell.to_source(code) ==
               ~S'''
               require Kino.RPC
               node = :name@node
               Node.set_cookie(node, :"node-cookie")

               Kino.RPC.eval_string(
                 node,
                 ~S"""
                 "Number #{1}"
                 """,
                 file: __ENV__.file
               )
               '''
               |> String.replace_trailing("\n", "")

      code = %{@attrs | "code" => ~S/"Number #{1}"/ <> "\n:ok"}

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
      attrs = %{@attrs | "assign_to" => "result"}

      assert RemoteExecutionCell.to_source(attrs) == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             result = Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "do not assign to an invalid variable" do
      attrs = %{@attrs | "assign_to" => "invalid result"}

      assert RemoteExecutionCell.to_source(attrs) == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, :"node-cookie")
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "cookie value from secret" do
      attrs =
        @attrs
        |> Map.drop(["cookie_text"])
        |> Map.merge(%{"cookie_source" => "secret", "cookie_secret" => "COOKIE_SECRET"})

      assert RemoteExecutionCell.to_source(attrs) == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, String.to_atom(System.fetch_env!("LB_COOKIE_SECRET")))
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "do not generate code for an invalid cookie secret" do
      attrs =
        @attrs
        |> Map.drop(["cookie_text"])
        |> Map.merge(%{"cookie_source" => "secret", "cookie_secret" => ""})

      assert RemoteExecutionCell.to_source(attrs) == ""
    end

    test "node name from secret" do
      attrs =
        @attrs
        |> Map.drop(["node_text"])
        |> Map.merge(%{"node_source" => "secret", "node_secret" => "NODE_SECRET"})

      assert RemoteExecutionCell.to_source(attrs) == """
             require Kino.RPC
             node = String.to_atom(System.fetch_env!("LB_NODE_SECRET"))
             Node.set_cookie(node, :"node-cookie")
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end

    test "do not generate code for an invalid node secret" do
      attrs =
        @attrs
        |> Map.drop(["node_text"])
        |> Map.merge(%{"node_source" => "secret", "node_secret" => ""})

      assert RemoteExecutionCell.to_source(attrs) == ""
    end
  end

  defmodule Global do
    use ExUnit.Case, async: false

    setup do
      AttributeStore.clear()
      on_exit(fn -> AttributeStore.clear() end)
    end

    test "reuses node and secret from previously started cell" do
      {kino, _source} = start_smart_cell!(RemoteExecutionCell, %{})

      push_event(kino, "update_field", %{"field" => "node_source", "value" => "text"})
      push_event(kino, "update_field", %{"field" => "node_text", "value" => "name@shared"})

      push_event(kino, "update_field", %{"field" => "cookie_source", "value" => "secret"})
      push_event(kino, "update_field", %{"field" => "cookie_secret", "value" => "COOKIE_SECRET"})

      push_smart_cell_editor_source(kino, ":hello")

      assert_smart_cell_update(kino, %{}, """
      require Kino.RPC
      node = :name@shared
      Node.set_cookie(node, String.to_atom(System.fetch_env!("LB_COOKIE_SECRET")))
      Kino.RPC.eval_string(node, ~S":hello", file: __ENV__.file)\
      """)

      # Next cell should have the same node and cookie

      {_kino, source} = start_smart_cell!(RemoteExecutionCell, %{})

      assert source == """
             require Kino.RPC
             node = :name@shared
             Node.set_cookie(node, String.to_atom(System.fetch_env!("LB_COOKIE_SECRET")))
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """

      # Init attrs take precedence

      attrs = %{"node_source" => "text", "node_text" => "name@node"}
      {_kino, source} = start_smart_cell!(RemoteExecutionCell, attrs)

      assert source == """
             require Kino.RPC
             node = :name@node
             Node.set_cookie(node, String.to_atom(System.fetch_env!("LB_COOKIE_SECRET")))
             Kino.RPC.eval_string(node, ~S":ok", file: __ENV__.file)\
             """
    end
  end
end
