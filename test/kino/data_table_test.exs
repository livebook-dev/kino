defmodule Kino.DataTableTest do
  use ExUnit.Case, async: true

  describe "start/1" do
    test "raises an error when structs are given" do
      assert_raise ArgumentError,
                   "struct records are not supported, you need to convert them to maps explicitly",
                   fn ->
                     Kino.DataTable.start([
                       URI.parse("https://elixir-lang.org"),
                       URI.parse("https://www.erlang.org")
                     ])
                   end
    end

    test "raises an error when records have invalid data type" do
      assert_raise ArgumentError,
                   "expected record to be either map, tuple or keyword list, got: \"value\"",
                   fn ->
                     Kino.DataTable.start(["value"])
                   end
    end

    test "raises an error when records have mixed data type" do
      assert_raise ArgumentError,
                   "expected records to have the same data type, found map and tuple",
                   fn ->
                     Kino.DataTable.start([%{id: 1, name: "Grumpy"}, {2, "Lil Bub"}])
                   end
    end

    test "does not validate enumerables other than list" do
      data = MapSet.new([%{id: 1, name: "Grumpy"}, {2, "Lil Bub"}])
      Kino.DataTable.start(data)
    end
  end

  @people_data [
    %{id: 3, name: "Amy Santiago"},
    %{id: 1, name: "Jake Peralta"},
    %{id: 2, name: "Terry Jeffords"}
  ]

  describe "connecting" do
    test "connect reply contains empty columns definition if there is no data" do
      widget = Kino.DataTable.start([])

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply, %{columns: [], features: [:pagination, :sorting]}}
    end

    test "connect reply contains columns definition if there is some data" do
      widget = Kino.DataTable.start(@people_data)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply,
                      %{
                        columns: [%{key: :id, label: ":id"}, %{key: :name, label: ":name"}],
                        features: [:pagination, :sorting]
                      }}
    end

    test "columns preserve attributes order when records are compatible keyword lists" do
      data = [
        [b: 1, a: 1],
        [b: 2, a: 2]
      ]

      widget = Kino.DataTable.start(data)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply,
                      %{
                        columns: [%{key: :b, label: ":b"}, %{key: :a, label: ":a"}]
                      }}
    end

    test "columns include all attributes when records with mixed attributes are given" do
      data = [
        %{b: 1, a: 1},
        %{b: 2, c: 2}
      ]

      widget = Kino.DataTable.start(data)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply,
                      %{
                        columns: [
                          %{key: :a, label: ":a"},
                          %{key: :b, label: ":b"},
                          %{key: :c, label: ":c"}
                        ]
                      }}
    end

    test "columns accommodate for the longest record when records are tuples of mixed length" do
      data = [
        {1, "Sherlock Holmes", 100},
        {2, "John Watson", 150, :doctor},
        {3}
      ]

      widget = Kino.DataTable.start(data)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply,
                      %{
                        columns: [
                          %{key: 0, label: "0"},
                          %{key: 1, label: "1"},
                          %{key: 2, label: "2"},
                          %{key: 3, label: "3"}
                        ]
                      }}
    end

    test "columns include only user-specified keys if given" do
      data = [
        %{b: 1, a: 1, c: 1},
        %{b: 2, a: 2, c: 2}
      ]

      widget = Kino.DataTable.start(data, keys: [:c, :b])

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply,
                      %{
                        columns: [%{key: :c, label: ":c"}, %{key: :b, label: ":b"}]
                      }}
    end
  end

  describe "querying rows" do
    test "preserves data order by default" do
      widget = Kino.DataTable.start(@people_data)
      connect_self(widget)

      spec = %{
        offset: 0,
        limit: 10,
        order_by: nil,
        order: :asc
      }

      send(widget.pid, {:get_rows, self(), spec})

      assert_receive {:rows,
                      %{
                        rows: [
                          %{id: _, fields: %{id: "3", name: ~s/"Amy Santiago"/}},
                          %{id: _, fields: %{id: "1", name: ~s/"Jake Peralta"/}},
                          %{id: _, fields: %{id: "2", name: ~s/"Terry Jeffords"/}}
                        ],
                        total_rows: 3,
                        columns: :initial
                      }}
    end

    test "supports sorting by other columns" do
      widget = Kino.DataTable.start(@people_data)
      connect_self(widget)

      spec = %{
        offset: 0,
        limit: 10,
        order_by: :name,
        order: :desc
      }

      send(widget.pid, {:get_rows, self(), spec})

      assert_receive {:rows,
                      %{
                        rows: [
                          %{id: _, fields: %{id: "2", name: ~s/"Terry Jeffords"/}},
                          %{id: _, fields: %{id: "1", name: ~s/"Jake Peralta"/}},
                          %{id: _, fields: %{id: "3", name: ~s/"Amy Santiago"/}}
                        ],
                        total_rows: 3,
                        columns: :initial
                      }}
    end

    test "supports offset and limit" do
      widget = Kino.DataTable.start(@people_data)
      connect_self(widget)

      spec = %{
        offset: 1,
        limit: 1,
        order_by: :id,
        order: :asc
      }

      send(widget.pid, {:get_rows, self(), spec})

      assert_receive {:rows,
                      %{
                        rows: [
                          %{id: _, fields: %{id: "2", name: ~s/"Terry Jeffords"/}}
                        ],
                        total_rows: 3,
                        columns: :initial
                      }}
    end

    test "sends only relevant fields if user-specified keys are given" do
      widget = Kino.DataTable.start(@people_data, keys: [:id])
      connect_self(widget)

      spec = %{
        offset: 0,
        limit: 10,
        order_by: nil,
        order: :asc
      }

      send(widget.pid, {:get_rows, self(), spec})

      assert_receive {:rows,
                      %{
                        rows: [
                          %{id: _, fields: %{id: "3"}},
                          %{id: _, fields: %{id: "1"}},
                          %{id: _, fields: %{id: "2"}}
                        ],
                        total_rows: 3,
                        columns: :initial
                      }}
    end
  end

  defp connect_self(widget) do
    send(widget.pid, {:connect, self()})
    assert_receive {:connect_reply, %{}}
  end
end
