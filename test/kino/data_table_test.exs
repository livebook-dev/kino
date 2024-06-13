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
               data: [["3", "Amy Santiago"], ["1", "Jake Peralta"], ["2", "Terry Jeffords"]],
               order: nil,
               total_rows: 3
             }
           } = data

    push_event(kino, "order_by", %{"key" => "0", "direction" => "desc"})

    data = connect(kino)

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":id"},
                 %{key: "1", label: ":name"}
               ],
               data: [["3", "Amy Santiago"], ["2", "Terry Jeffords"], ["1", "Jake Peralta"]],
               order: %{key: "0", direction: :desc},
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
               columns: [%{key: "0", label: "b"}, %{key: "1", label: "a"}],
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

  test "supports non-charlist List values" do
    entries = [
      [
        {"a", [1, "b"]},
        {"b", [~N"2000-01-01 00:00:00", %User{id: 1, name: "User"}]},
        {"c", [90, 10_000_000]}
      ]
    ]

    kino = Kino.DataTable.new(entries)
    data = connect(kino)

    assert %{
             content: %{
               data: [
                 [
                   ~s/[1, "b"]/,
                   ~s/[~N[2000-01-01 00:00:00], %Kino.DataTableTest.User{__meta__: nil, id: 1, name: "User"}]/,
                   "[90, 10000000]"
                 ]
               ]
             }
           } = data
  end

  test "supports non-utf8 binary values" do
    entries = [
      binaries: [<<110, 120>>, <<200, 210>>]
    ]

    kino = Kino.DataTable.new(entries)
    data = connect(kino)

    assert %{
             content: %{
               data: [["nx"], ["<<200, 210>>"]]
             }
           } = data
  end

  test "supports empty data" do
    kino = Kino.DataTable.new([])
    data = connect(kino)

    assert %{content: %{data: []}} = data
  end

  test "sends only relevant fields if user-specified keys are given" do
    kino = Kino.DataTable.new(@people_entries, keys: [:id])
    data = connect(kino)

    assert data.content.data == [["3"], ["1"], ["2"]]
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
               data: [["3", "Amy Santiago"], ["1", "Jake Peralta"], ["2", "Terry Jeffords"]],
               order: nil,
               page: 1,
               max_page: 1
             }
           } = data
  end

  test "supports sorting by other columns" do
    kino = Kino.DataTable.new(@people_entries)

    # Get initial data to populate the key-string mapping
    connect(kino)

    push_event(kino, "order_by", %{"key" => "1", "direction" => "desc"})

    assert_broadcast_event(kino, "update_content", %{
      columns: [
        %{key: "0", label: ":id"},
        %{key: "1", label: ":name"}
      ],
      data: [["2", "Terry Jeffords"], ["1", "Jake Peralta"], ["3", "Amy Santiago"]],
      order: %{key: "1", direction: :desc}
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
               data: [["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["10"]]
             }
           } = data

    push_event(kino, "show_page", %{"page" => 2})

    assert_broadcast_event(kino, "update_content", %{
      page: 2,
      max_page: 3,
      data: [["11"], ["12"], ["13"] | _]
    })
  end

  test "supports setting table name" do
    kino = Kino.DataTable.new([x: 1..10, y: 1..10], name: "Example")
    data = connect(kino)
    assert %{name: "Example"} = data
  end

  test "supports sliceable data" do
    entries = %{x: 1..3, y: 1..3}

    kino = Kino.DataTable.new(entries, keys: [:x, :y])
    data = connect(kino)

    assert %{
             content: %{
               columns: [%{key: "0", label: ":x"}, %{key: "1", label: ":y"}],
               data: [["1", "1"], ["2", "2"], ["3", "3"]],
               total_rows: 3
             }
           } = data
  end

  test "correctly paginates sliceable data" do
    entries = %{x: 1..30, y: 1..30}

    kino = Kino.DataTable.new(entries, keys: [:x, :y])
    data = connect(kino)

    assert %{
             content: %{
               columns: [%{key: "0", label: ":x"}, %{key: "1", label: ":y"}],
               data: [["1", "1"], ["2", "2"], ["3", "3"] | _] = rows,
               total_rows: 30
             }
           } = data

    assert length(rows) == 10

    push_event(kino, "show_page", %{"page" => 2})

    assert_broadcast_event(kino, "update_content", %{
      data: [["11", "11"], ["12", "12"] | _]
    })

    push_event(kino, "show_page", %{"page" => 1})

    assert_broadcast_event(kino, "update_content", %{
      data: [["1", "1"], ["2", "2"] | _]
    })
  end

  test "supports a formatter option" do
    entries = %{x: 1..3, y: [1.1, 1.2, 1.3]}

    formatter =
      fn
        :__header__, value -> {:ok, "h:#{value}"}
        :x, value when is_integer(value) -> {:ok, "x:#{value}"}
        _, _ -> :default
      end

    kino = Kino.DataTable.new(entries, keys: [:x, :y], formatter: formatter)
    data = connect(kino)

    assert %{
             content: %{
               columns: [%{key: "0", label: "h:x"}, %{key: "1", label: "h:y"}],
               data: [["x:1", "1.1"], ["x:2", "1.2"], ["x:3", "1.3"]],
               total_rows: 3
             }
           } = data
  end

  test "supports data update" do
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

    new_entries = [
      %User{id: 1, name: "Sherlock Holmes"},
      %User{id: 2, name: "John Watson"},
      %User{id: 3, name: "Tuka Tuka"}
    ]

    Kino.DataTable.update(kino, new_entries)

    assert_broadcast_event(kino, "update_content", %{
      data: [["1", "Sherlock Holmes"], ["2", "John Watson"], ["3", "Tuka Tuka"]],
      total_rows: 3
    })
  end
end
