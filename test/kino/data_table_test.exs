defmodule Kino.DataTableTest do
  use Kino.LivebookCase, async: true

  @people_entries [
    %{id: 3, name: "Amy Santiago"},
    %{id: 1, name: "Jake Peralta"},
    %{id: 2, name: "Terry Jeffords"}
  ]

  test "initial data respects current query parameters" do
    kino = Kino.DataTable.new(@people_entries)
    data = connect(kino)

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
               total_rows: 3
             }
           } = data

    send(
      kino.pid,
      {:event, "order_by", %{"key" => "0", "order" => "desc"}, %{origin: self()}}
    )

    data = connect(kino)

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
               order_by: "0",
               total_rows: 3
             }
           } = data
  end

  test "columns preserve attributes order when records are key-value lists" do
    entries = [
      [b: 1, a: 1],
      [b: 2, a: 2]
    ]

    kino = Kino.DataTable.new(entries)
    data = connect(kino)

    assert %{
             content: %{
               columns: [%{key: "0", label: ":b"}, %{key: "1", label: ":a"}],
               total_rows: 2
             }
           } = data
  end

  test "supports key-value lists with string keys" do
    entries = [
      [{"b", 1}, {"a", 1}],
      [{"b", 2}, {"a", 2}]
    ]

    kino = Kino.DataTable.new(entries)
    data = connect(kino)

    assert %{
             content: %{
               columns: [%{key: "0", label: ~s/"b"/}, %{key: "1", label: ~s/"a"/}],
               total_rows: 2
             }
           } = data
  end

  defmodule User do
    defstruct [:__meta__, :id, :name]
  end

  test "supports a list of structs ignoring underscored attributes" do
    entries = [
      %User{id: 1, name: "Sherlock Holmes"},
      %User{id: 2, name: "John Watson"}
    ]

    kino = Kino.DataTable.new(entries)
    data = connect(kino)

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":id"},
                 %{key: "1", label: ":name"}
               ],
               total_rows: 2
             }
           } = data
  end

  test "sends only relevant fields if user-specified keys are given" do
    kino = Kino.DataTable.new(@people_entries, keys: [:id])
    data = connect(kino)

    assert data.content.rows == [
             %{fields: %{"0" => "3"}},
             %{fields: %{"0" => "1"}},
             %{fields: %{"0" => "2"}}
           ]
  end

  test "respects :keys order" do
    kino = Kino.DataTable.new(@people_entries, keys: [:name, :id])
    data = connect(kino)

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":name"},
                 %{key: "1", label: ":id"}
               ]
             }
           } = data
  end

  test "preserves data order by default" do
    kino = Kino.DataTable.new(@people_entries)
    data = connect(kino)

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
    kino = Kino.DataTable.new(@people_entries)

    # Get initial data to populate the key-string mapping
    connect(kino)

    push_event(kino, "order_by", %{"key" => "1", "order" => "desc"})

    assert_broadcast_event(kino, "update_content", %{
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

    kino = Kino.DataTable.new(entries)
    data = connect(kino)

    assert %{
             content: %{
               page: 1,
               max_page: 3,
               rows: [%{fields: %{"0" => "1"}} | _]
             }
           } = data

    push_event(kino, "show_page", %{"page" => 2})

    assert_broadcast_event(kino, "update_content", %{
      page: 2,
      max_page: 3,
      rows: [%{fields: %{"0" => "11"}} | _]
    })
  end

  test "supports setting table name" do
    kino = Kino.DataTable.new([x: 1..10, y: 1..10], name: "Example")
    data = connect(kino)
    assert %{name: "Example"} = data
  end

  test "supports sliceable data" do
    entries = %{x: 1..3, y: 1..3}

    kino = Kino.DataTable.new(entries)
    data = connect(kino)

    assert %{
             content: %{
               columns: [%{key: "0", label: ":x"}, %{key: "1", label: ":y"}],
               rows: [
                 %{fields: %{"0" => "1", "1" => "1"}},
                 %{fields: %{"0" => "2", "1" => "2"}},
                 %{fields: %{"0" => "3", "1" => "3"}}
               ],
               total_rows: 3
             }
           } = data
  end

  test "correctly paginates sliceable data" do
    entries = %{x: 1..30, y: 1..30}

    kino = Kino.DataTable.new(entries)
    data = connect(kino)

    assert %{
             content: %{
               columns: [%{key: "0", label: ":x"}, %{key: "1", label: ":y"}],
               rows: [%{fields: %{"0" => "1", "1" => "1"}} | _] = rows,
               total_rows: 30
             }
           } = data

    assert length(rows) == 10

    push_event(kino, "show_page", %{"page" => 2})

    assert_broadcast_event(kino, "update_content", %{
      rows: [%{fields: %{"0" => "11", "1" => "11"}} | _]
    })

    push_event(kino, "show_page", %{"page" => 1})

    assert_broadcast_event(kino, "update_content", %{
      rows: [%{fields: %{"0" => "1", "1" => "1"}} | _]
    })
  end
end
