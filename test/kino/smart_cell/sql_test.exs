defmodule Kino.SmartCell.SQLTest do
  use Kino.LivebookCase, async: true

  import KinoTest.JS.Live
  import KinoTest.SmartCell

  alias Kino.SmartCell.SQL

  describe "initialization" do
    test "restores source code from attrs" do
      attrs = %{
        "connection" => %{"variable" => "db", "type" => "postgres"},
        "result_variable" => "ids_result",
        "query" => "SELECT id FROM users"
      }

      {_widget, source} = start_smart_cell!(SQL, attrs)

      assert source ==
               """
               ids_result = Postgrex.query!(db, "SELECT id FROM users", [])\
               """
    end
  end

  test "when an invalid result variable name is set, restores the previous value" do
    {widget, _source} = start_smart_cell!(SQL, %{"result_variable" => "result"})

    push_event(widget, "update_result_variable", "RESULT")

    assert_broadcast_event(widget, "update_result_variable", "result")
  end

  test "finds database connections in binding and sends them to the client" do
    {widget, _source} = start_smart_cell!(SQL, %{})

    parent = self()

    spawn_link(fn ->
      # Pretend we are a connection pool for Postgrex
      DBConnection.register_as_pool(Postgrex.Protocol)
      send(parent, {:ready, self()})
      assert_receive :stop
    end)

    assert_receive {:ready, conn_pid}

    binding = [non_conn: self(), conn: conn_pid]
    # TODO: Use Code.env_for_eval on Elixir v1.14+
    env = :elixir.env_for_eval([])
    SQL.scan_binding(widget.pid, binding, env)

    connection = %{variable: "conn", type: "postgres"}

    assert_broadcast_event(widget, "connections", %{
      "connections" => [^connection],
      "connection" => ^connection
    })

    send(conn_pid, :stop)
  end

  describe "code generation" do
    test "uses regular string for a single-line query" do
      attrs = %{
        "connection" => %{"variable" => "conn", "type" => "postgres"},
        "result_variable" => "result",
        "query" => "SELECT id FROM users"
      }

      assert SQL.to_source(attrs) == """
             result = Postgrex.query!(conn, "SELECT id FROM users", [])\
             """

      assert SQL.to_source(put_in(attrs["connection"]["type"], "mysql")) == """
             result = MyXQL.query!(conn, "SELECT id FROM users", [])\
             """
    end

    test "uses heredoc string for a multi-line query" do
      attrs = %{
        "connection" => %{"variable" => "conn", "type" => "postgres"},
        "result_variable" => "result",
        "query" => "SELECT id FROM users\nWHERE last_name = 'Sherlock'"
      }

      assert SQL.to_source(attrs) == ~s'''
             result =
               Postgrex.query!(
                 conn,
                 """
                 SELECT id FROM users
                 WHERE last_name = 'Sherlock'
                 """,
                 []
               )\
             '''

      assert SQL.to_source(put_in(attrs["connection"]["type"], "mysql")) == ~s'''
             result =
               MyXQL.query!(
                 conn,
                 """
                 SELECT id FROM users
                 WHERE last_name = 'Sherlock'
                 """,
                 []
               )\
             '''
    end

    test "parses parameter expressions" do
      attrs = %{
        "connection" => %{"variable" => "conn", "type" => "postgres"},
        "result_variable" => "result",
        "query" => ~s/SELECT id FROM users WHERE id {{user_id}} AND name LIKE {{search <> "%"}}/
      }

      assert SQL.to_source(attrs) == ~s'''
             result =
               Postgrex.query!(conn, "SELECT id FROM users WHERE id $1 AND name LIKE $2", [
                 user_id,
                 search <> "%"
               ])\
             '''

      assert SQL.to_source(put_in(attrs["connection"]["type"], "mysql")) == ~s'''
             result =
               MyXQL.query!(conn, "SELECT id FROM users WHERE id ? AND name LIKE ?", [
                 user_id,
                 search <> "%"
               ])\
             '''
    end

    test "ignores parameters inside comments" do
      attrs = %{
        "connection" => %{"variable" => "conn", "type" => "postgres"},
        "result_variable" => "result",
        "query" => """
        SELECT id from users
        -- WHERE id = {{user_id1}}
        /* WHERE id = {{user_id2}} */ WHERE id = {{user_id3}}\
        """
      }

      assert SQL.to_source(attrs) == ~s'''
             result =
               Postgrex.query!(
                 conn,
                 """
                 SELECT id from users
                 -- WHERE id = {{user_id1}}
                 /* WHERE id = {{user_id2}} */ WHERE id = $1
                 """,
                 [user_id3]
               )\
             '''

      assert SQL.to_source(put_in(attrs["connection"]["type"], "mysql")) == ~s'''
             result =
               MyXQL.query!(
                 conn,
                 """
                 SELECT id from users
                 -- WHERE id = {{user_id1}}
                 /* WHERE id = {{user_id2}} */ WHERE id = ?
                 """,
                 [user_id3]
               )\
             '''
    end
  end
end
