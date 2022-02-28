defmodule Kino.SmartCell.DBConnectionTest do
  use Kino.LivebookCase, async: true

  import KinoTest.JS.Live
  import KinoTest.SmartCell

  alias Kino.SmartCell.DBConnection

  describe "initialization" do
    test "returns default source when started with empty attrs" do
      {_widget, source} = start_smart_cell!(DBConnection, %{})

      assert source ==
               """
               opts = [hostname: "", port: 5432, username: "", password: "", database: ""]
               {:ok, conn} = Kino.start_child({Postgrex, opts})\
               """
    end

    test "restores source code from attrs" do
      attrs = %{
        "variable" => "db",
        "type" => "mysql",
        "hostname" => "localhost",
        "port" => 4444,
        "username" => "admin",
        "password" => "pass",
        "database" => "default"
      }

      {_widget, source} = start_smart_cell!(DBConnection, attrs)

      assert source ==
               """
               opts = [
                 hostname: "localhost",
                 port: 4444,
                 username: "admin",
                 password: "pass",
                 database: "default"
               ]

               {:ok, db} = Kino.start_child({MyXQL, opts})\
               """
    end
  end

  test "when a field changes, broadcasts the change and sends source update" do
    {widget, _source} = start_smart_cell!(DBConnection, %{})

    push_event(widget, "update_field", %{"field" => "hostname", "value" => "localhost"})

    assert_broadcast_event(widget, "update", %{"fields" => %{"hostname" => "localhost"}})

    assert_source_update(widget, %{"hostname" => "localhost"}, """
    opts = [hostname: "localhost", port: 5432, username: "", password: "", database: ""]
    {:ok, conn} = Kino.start_child({Postgrex, opts})\
    """)
  end

  test "when an invalid variable name is set, restores the previous value" do
    {widget, _source} = start_smart_cell!(DBConnection, %{"variable" => "db"})

    push_event(widget, "update_field", %{"field" => "variable", "value" => "DB"})

    assert_broadcast_event(widget, "update", %{"fields" => %{"variable" => "db"}})
  end

  test "when the database type changes, restores the default port for that database" do
    {widget, _source} = start_smart_cell!(DBConnection, %{"type" => "postgres", "port" => 5432})

    push_event(widget, "update_field", %{"field" => "type", "value" => "mysql"})

    assert_broadcast_event(widget, "update", %{"fields" => %{"type" => "mysql", "port" => 3306}})

    assert_source_update(widget, %{"type" => "mysql", "port" => 3306}, """
    opts = [hostname: "", port: 3306, username: "", password: "", database: ""]
    {:ok, conn} = Kino.start_child({MyXQL, opts})\
    """)
  end
end
