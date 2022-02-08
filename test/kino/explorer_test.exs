defmodule Kino.ExplorerTest do
  use Kino.LivebookCase, async: true

  import KinoTest.JS.Live

  defp people_df() do
    Explorer.DataFrame.from_map(%{
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
                 %{key: "0", label: "id", type: "integer"},
                 %{key: "1", label: "name", type: "string"}
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
        %{key: "0", label: "id", type: "integer"},
        %{key: "1", label: "name", type: "string"}
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
    df = Explorer.DataFrame.from_map(%{n: Enum.to_list(1..25)})

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
end
