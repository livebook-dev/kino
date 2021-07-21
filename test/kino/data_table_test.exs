defmodule Kino.DataTableTest do
  use ExUnit.Case, async: true

  describe "new/1" do
    test "raises an error when records have invalid data type" do
      assert_raise ArgumentError,
                   "expected record to be either map, struct, tuple or keyword list, got: \"value\"",
                   fn ->
                     Kino.DataTable.new(["value"])
                   end
    end

    test "raises an error when records have mixed data type" do
      assert_raise ArgumentError,
                   "expected records to have the same data type, found map and tuple",
                   fn ->
                     Kino.DataTable.new([%{id: 1, name: "Grumpy"}, {2, "Lil Bub"}])
                   end
    end

    test "does not validate enumerables other than list" do
      data = MapSet.new([%{id: 1, name: "Grumpy"}, {2, "Lil Bub"}])
      Kino.DataTable.new(data)
    end
  end

  @people_data [
    %{id: 3, name: "Amy Santiago"},
    %{id: 1, name: "Jake Peralta"},
    %{id: 2, name: "Terry Jeffords"}
  ]

  describe "connecting" do
    test "connect reply contains empty columns definition if the :keys option is not given" do
      widget = Kino.DataTable.new(@people_data)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply, %{columns: [], features: _features}}
    end

    test "connect reply contains columns definition if the :keys option is given" do
      widget = Kino.DataTable.new(@people_data, keys: [:id, :name])

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply,
                      %{
                        columns: [%{key: :id, label: ":id"}, %{key: :name, label: ":name"}],
                        features: _features
                      }}
    end

    test "sorting is enabled by default when a list is given" do
      widget = Kino.DataTable.new([])

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply, %{features: [:pagination, :sorting]}}
    end

    test "sorting is disabled by default when non-list is given" do
      widget = Kino.DataTable.new(MapSet.new())

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply, %{features: [:pagination]}}
    end

    test "sorting is enabled when set explicitly with :enable_sorting" do
      widget = Kino.DataTable.new(MapSet.new(), sorting_enabled: true)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply, %{features: [:pagination, :sorting]}}
    end
  end

  @default_rows_spec %{offset: 0, limit: 10, order_by: nil, order: :asc}

  describe "querying rows" do
    test "columns preserve attributes order when records are compatible keyword lists" do
      data = [
        [b: 1, a: 1],
        [b: 2, a: 2]
      ]

      widget = Kino.DataTable.new(data)
      connect_self(widget)

      send(widget.pid, {:get_rows, self(), @default_rows_spec})

      assert_receive {:rows,
                      %{
                        columns: [%{key: :b, label: ":b"}, %{key: :a, label: ":a"}]
                      }}
    end

    test "columns include all attributes when records with mixed attributes are given" do
      data = [
        %{b: 1, a: 1},
        %{b: 2, c: 2}
      ]

      widget = Kino.DataTable.new(data)
      connect_self(widget)

      send(widget.pid, {:get_rows, self(), @default_rows_spec})

      assert_receive {:rows,
                      %{
                        columns: [
                          %{key: :a, label: ":a"},
                          %{key: :b, label: ":b"},
                          %{key: :c, label: ":c"}
                        ]
                      }}
    end

    defmodule User do
      defstruct [:__meta__, :id, :name]
    end

    test "columns don't include underscored attributes by default" do
      data = [
        %User{id: 1, name: "Sherlock Holmes"},
        %User{id: 2, name: "John Watson"}
      ]

      widget = Kino.DataTable.new(data)
      connect_self(widget)

      send(widget.pid, {:get_rows, self(), @default_rows_spec})

      assert_receive {:rows,
                      %{
                        columns: [
                          %{key: :id, label: ":id"},
                          %{key: :name, label: ":name"}
                        ]
                      }}
    end

    test "columns include underscored attributes if the :show_underscored option is set" do
      data = [
        %User{id: 1, name: "Sherlock Holmes"},
        %User{id: 2, name: "John Watson"}
      ]

      widget = Kino.DataTable.new(data, show_underscored: true)
      connect_self(widget)

      send(widget.pid, {:get_rows, self(), @default_rows_spec})

      assert_receive {:rows,
                      %{
                        columns: [
                          %{key: :__meta__, label: ":__meta__"},
                          %{key: :__struct__, label: ":__struct__"},
                          %{key: :id, label: ":id"},
                          %{key: :name, label: ":name"}
                        ]
                      }}
    end

    test "columns accommodate for the longest record when records are tuples of mixed length" do
      data = [
        {1, "Sherlock Holmes", 100},
        {2, "John Watson", 150, :doctor},
        {3}
      ]

      widget = Kino.DataTable.new(data)
      connect_self(widget)

      send(widget.pid, {:get_rows, self(), @default_rows_spec})

      assert_receive {:rows,
                      %{
                        columns: [
                          %{key: 0, label: "0"},
                          %{key: 1, label: "1"},
                          %{key: 2, label: "2"},
                          %{key: 3, label: "3"}
                        ]
                      }}
    end

    test "columns are reused if the :keys option is given" do
      widget = Kino.DataTable.new(@people_data, keys: [:name])
      connect_self(widget)

      send(widget.pid, {:get_rows, self(), @default_rows_spec})

      assert_receive {:rows, %{columns: :initial}}
    end

    test "preserves data order by default" do
      widget = Kino.DataTable.new(@people_data)
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
                        columns: _columns
                      }}
    end

    test "supports sorting by other columns" do
      widget = Kino.DataTable.new(@people_data)
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
                        columns: _columns
                      }}
    end

    test "supports offset and limit" do
      widget = Kino.DataTable.new(@people_data)
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
                        columns: _columns
                      }}
    end

    test "sends only relevant fields if user-specified keys are given" do
      widget = Kino.DataTable.new(@people_data, keys: [:id])
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
                        columns: _columns
                      }}
    end
  end

  defp connect_self(widget) do
    send(widget.pid, {:connect, self()})
    assert_receive {:connect_reply, %{}}
  end
end
