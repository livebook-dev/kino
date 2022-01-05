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

  @people_entries [
    %{id: 3, name: "Amy Santiago"},
    %{id: 1, name: "Jake Peralta"},
    %{id: 2, name: "Terry Jeffords"}
  ]

  test "sorting is enabled by default when a list is given" do
    widget = Kino.DataTable.new([])
    data = connect_self(widget)

    assert %{features: [:pagination, :sorting]} = data
  end

  test "sorting is disabled by default when non-list is given" do
    widget = Kino.DataTable.new(MapSet.new())
    data = connect_self(widget)

    assert %{features: [:pagination]} = data
  end

  test "sorting is enabled when set explicitly with :enable_sorting" do
    widget = Kino.DataTable.new(MapSet.new(), sorting_enabled: true)
    data = connect_self(widget)

    assert %{features: [:pagination, :sorting]} = data
  end

  test "initial data respects current query parameters" do
    widget = Kino.DataTable.new(@people_entries)
    data = connect_self(widget)

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":id"},
                 %{key: "1", label: ":name"}
               ],
               rows: [
                 %{fields: %{"0" => "3", "1" => ~s/"Amy Santiago"/}},
                 %{fields: %{"0" => "1", "1" => ~s/"Jake Peralta"/}},
                 %{fields: %{"0" => "2", "1" => ~s/"Terry Jeffords"/}}
               ],
               order: :asc,
               order_by: nil
             }
           } = data

    send(
      widget.pid,
      {:event, "order_by", %{"key" => "0", "order" => "desc"}, %{origin: self()}}
    )

    data = connect_self(widget)

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":id"},
                 %{key: "1", label: ":name"}
               ],
               rows: [
                 %{fields: %{"0" => "3", "1" => ~s/"Amy Santiago"/}},
                 %{fields: %{"0" => "2", "1" => ~s/"Terry Jeffords"/}},
                 %{fields: %{"0" => "1", "1" => ~s/"Jake Peralta"/}}
               ],
               order: :desc,
               order_by: "0"
             }
           } = data
  end

  test "columns preserve attributes order when records are compatible keyword lists" do
    entries = [
      [b: 1, a: 1],
      [b: 2, a: 2]
    ]

    widget = Kino.DataTable.new(entries)
    data = connect_self(widget)

    assert %{
             content: %{
               columns: [%{key: "0", label: ":b"}, %{key: "1", label: ":a"}]
             }
           } = data
  end

  test "columns include all attributes when records with mixed attributes are given" do
    entries = [
      %{b: 1, a: 1},
      %{b: 2, c: 2}
    ]

    widget = Kino.DataTable.new(entries)
    data = connect_self(widget)

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":a"},
                 %{key: "1", label: ":b"},
                 %{key: "2", label: ":c"}
               ]
             }
           } = data
  end

  defmodule User do
    defstruct [:__meta__, :id, :name]
  end

  test "columns don't include underscored attributes by default" do
    entries = [
      %User{id: 1, name: "Sherlock Holmes"},
      %User{id: 2, name: "John Watson"}
    ]

    widget = Kino.DataTable.new(entries)
    data = connect_self(widget)

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":id"},
                 %{key: "1", label: ":name"}
               ]
             }
           } = data
  end

  test "columns include underscored attributes if the :show_underscored option is set" do
    entries = [
      %User{id: 1, name: "Sherlock Holmes"},
      %User{id: 2, name: "John Watson"}
    ]

    widget = Kino.DataTable.new(entries, show_underscored: true)
    data = connect_self(widget)

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":__meta__"},
                 %{key: "1", label: ":__struct__"},
                 %{key: "2", label: ":id"},
                 %{key: "3", label: ":name"}
               ]
             }
           } = data
  end

  test "columns accommodate for the longest record when records are tuples of mixed length" do
    entries = [
      {1, "Sherlock Holmes", 100},
      {2, "John Watson", 150, :doctor},
      {3}
    ]

    widget = Kino.DataTable.new(entries)
    data = connect_self(widget)

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: "0"},
                 %{key: "1", label: "1"},
                 %{key: "2", label: "2"},
                 %{key: "3", label: "3"}
               ]
             }
           } = data
  end

  test "sends only relevant fields if user-specified keys are given" do
    widget = Kino.DataTable.new(@people_entries, keys: [:id])
    data = connect_self(widget)

    assert data.content.rows == [
             %{fields: %{"0" => "3"}},
             %{fields: %{"0" => "1"}},
             %{fields: %{"0" => "2"}}
           ]
  end

  test "preserves data order by default" do
    widget = Kino.DataTable.new(@people_entries)
    data = connect_self(widget)

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":id"},
                 %{key: "1", label: ":name"}
               ],
               rows: [
                 %{fields: %{"0" => "3", "1" => ~s/"Amy Santiago"/}},
                 %{fields: %{"0" => "1", "1" => ~s/"Jake Peralta"/}},
                 %{fields: %{"0" => "2", "1" => ~s/"Terry Jeffords"/}}
               ],
               order: :asc,
               order_by: nil,
               page: 1,
               max_page: 1
             }
           } = data
  end

  test "supports sorting by other columns" do
    widget = Kino.DataTable.new(@people_entries)
    connect_self(widget)

    send(
      widget.pid,
      {:event, "order_by", %{"key" => "1", "order" => "desc"}, %{origin: self()}}
    )

    assert {:event, "update_content",
            %{
              columns: [
                %{key: "0", label: ":id"},
                %{key: "1", label: ":name"}
              ],
              rows: [
                %{fields: %{"0" => "2", "1" => ~s/"Terry Jeffords"/}},
                %{fields: %{"0" => "1", "1" => ~s/"Jake Peralta"/}},
                %{fields: %{"0" => "3", "1" => ~s/"Amy Santiago"/}}
              ],
              order: :desc,
              order_by: "0"
            }}
  end

  test "supports pagination" do
    entries = for n <- 1..25, do: %{n: n}

    widget = Kino.DataTable.new(entries)
    data = connect_self(widget)

    assert %{
             content: %{
               page: 1,
               max_page: 3,
               rows: [%{fields: %{"0" => "1"}} | _]
             }
           } = data

    send(widget.pid, {:event, "show_page", %{"page" => 2}, %{origin: self()}})

    assert_receive {:event, "update_content",
                    %{
                      page: 2,
                      max_page: 3,
                      rows: [%{fields: %{"0" => "11"}} | _]
                    }, %{}}
  end

  defp connect_self(widget) do
    send(widget.pid, {:connect, self(), %{origin: self()}})
    assert_receive {:connect_reply, %{} = data, %{}}
    data
  end
end
