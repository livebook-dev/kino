defmodule Kino.ExplorerTest do
  use Kino.LivebookCase, async: true

  defp people_df() do
    Explorer.DataFrame.new(%{
      id: [3, 1, 2],
      name: ["Amy Santiago", "Jake Peralta", "Terry Jeffords"]
    })
  end

  test "column definitions include type" do
    widget = Kino.Explorer.new(people_df())
    data = connect(widget)

    assert %{
             features: [:pagination, :sorting],
             content: %{
               columns: [
                 %{key: "0", label: "id", type: "number"},
                 %{key: "1", label: "name", type: "text"}
               ]
             }
           } = data
  end

  test "rows order matches the given data frame by default" do
    widget = Kino.Explorer.new(people_df())
    data = connect(widget)

    assert %{
             content: %{
               rows: [
                 %{fields: %{"0" => "3", "1" => "Amy Santiago"}},
                 %{fields: %{"0" => "1", "1" => "Jake Peralta"}},
                 %{fields: %{"0" => "2", "1" => "Terry Jeffords"}}
               ],
               total_rows: 3
             }
           } = data
  end

  test "supports sorting by other columns" do
    widget = Kino.Explorer.new(people_df())

    connect(widget)

    push_event(widget, "order_by", %{"key" => "1", "order" => "desc"})

    assert_broadcast_event(widget, "update_content", %{
      columns: [
        %{key: "0", label: "id", type: "number"},
        %{key: "1", label: "name", type: "text"}
      ],
      rows: [
        %{fields: %{"0" => "2", "1" => "Terry Jeffords"}},
        %{fields: %{"0" => "1", "1" => "Jake Peralta"}},
        %{fields: %{"0" => "3", "1" => "Amy Santiago"}}
      ],
      order: :desc,
      order_by: "1"
    })
  end

  test "supports pagination" do
    df = Explorer.DataFrame.new(%{n: Enum.to_list(1..25)})

    widget = Kino.Explorer.new(df)
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

  test "supports pagination limit" do
    df = Explorer.DataFrame.new(%{n: Enum.to_list(1..25)})

    widget = Kino.Explorer.new(df)
    data = connect(widget)

    assert %{
             content: %{
               page: 1,
               max_page: 3,
               rows: [%{fields: %{"0" => "1"}} | _]
             }
           } = data

    push_event(widget, "limit", %{"limit" => 15})

    assert_broadcast_event(widget, "update_content", %{
      page: 1,
      max_page: 2,
      rows: [%{fields: %{"0" => "1"}} | _]
    })
  end

  test "supports data summary" do
    df =
      Explorer.DataFrame.new(%{
        id: [3, 1, 2, nil],
        name: ["Amy Santiago", "Jake Peralta", "Terry Jeffords", "Jake Peralta"]
      })

    widget = Kino.Explorer.new(df)
    data = connect(widget)

    assert %{
             content: %{
               columns: [
                 %{
                   key: "0",
                   label: "id",
                   summary: %{max: 3.0, mean: 2.0, min: 1.0, nulls: 1},
                   type: "number"
                 },
                 %{
                   key: "1",
                   label: "name",
                   summary: %{nulls: 0, top: "Jake Peralta", top_freq: 2, unique: 3},
                   type: "text"
                 }
               ]
             }
           } = data
  end

  test "support types" do
    df =
      Explorer.DataFrame.new(
        a: ["a", "b"],
        b: [1, 2],
        c: ["https://elixir-lang.org", "https://www.erlang.org"]
      )

    widget = Kino.Explorer.new(df)
    data = connect(widget)

    assert get_in(data.content.columns, [Access.all(), :type]) == ["text", "number", "uri"]
  end
end
