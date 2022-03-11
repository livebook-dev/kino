defmodule Kino.DataTableTest do
  use Kino.LivebookCase, async: true

  import KinoTest.JS.Live

  describe "new/1" do
    test "raises an error when records have invalid data type" do
      assert_raise ArgumentError,
                   "expected record to be either map, struct or keyword list, got: \"value\"",
                   fn ->
                     Kino.DataTable.new(["value"])
                   end
    end

    test "raises an error when records have mixed data type" do
      assert_raise ArgumentError,
                   "expected records to have the same data type, found map and keyword_list",
                   fn ->
                     Kino.DataTable.new([%{id: 1, name: "Grumpy"}, [name: "Lil Bub"]])
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
    data = connect(widget)

    assert %{features: [:pagination, :sorting]} = data
  end

  test "sorting is disabled by default when non-list is given" do
    widget = Kino.DataTable.new(MapSet.new())
    data = connect(widget)

    assert %{features: [:pagination]} = data
  end

  test "sorting is enabled when set explicitly with :enable_sorting" do
    widget = Kino.DataTable.new(MapSet.new(), sorting_enabled: true)
    data = connect(widget)

    assert %{features: [:pagination, :sorting]} = data
  end

  test "initial data respects current query parameters" do
    widget = Kino.DataTable.new(@people_entries)
    data = connect(widget)

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

    data = connect(widget)

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
    data = connect(widget)

    assert %{
             content: %{
               columns: [%{key: "0", label: ":b"}, %{key: "1", label: ":a"}]
             }
           } = data
  end

  test "columns include only attributes from the first record" do
    entries = [
      %{b: 1, a: 1},
      %{b: 2, c: 2}
    ]

    widget = Kino.DataTable.new(entries)
    data = connect(widget)

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":a"},
                 %{key: "1", label: ":b"}
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
    data = connect(widget)

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
    data = connect(widget)

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

  test "sends only relevant fields if user-specified keys are given" do
    widget = Kino.DataTable.new(@people_entries, keys: [:id])
    data = connect(widget)

    assert data.content.rows == [
             %{fields: %{"0" => "3"}},
             %{fields: %{"0" => "1"}},
             %{fields: %{"0" => "2"}}
           ]
  end

  test "preserves data order by default" do
    widget = Kino.DataTable.new(@people_entries)
    data = connect(widget)

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

    # Get initial data to populate the key-string mapping
    connect(widget)

    push_event(widget, "order_by", %{"key" => "1", "order" => "desc"})

    assert_broadcast_event(widget, "update_content", %{
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
      order_by: "1"
    })
  end

  test "supports pagination" do
    entries = for n <- 1..25, do: %{n: n}

    widget = Kino.DataTable.new(entries)
    data = connect(widget)

    assert %{
             content: %{
               page: 1,
               max_page: 3,
               rows: [%{fields: %{"0" => "1"}} | _]
             }
           } = data

    push_event(widget, "show_page", %{"page" => 2})

    assert_broadcast_event(widget, "update_content", %{
      page: 2,
      max_page: 3,
      rows: [%{fields: %{"0" => "11"}} | _]
    })
  end

  test "default table name is Data" do
    widget = Kino.DataTable.new([])
    data = connect(widget)
    assert %{name: "Data"} = data
  end

  test "supports setting table name" do
    widget = Kino.DataTable.new([], name: "Example")
    data = connect(widget)
    assert %{name: "Example"} = data
  end
end
