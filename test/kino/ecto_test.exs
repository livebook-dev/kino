defmodule Kino.EctoTest do
  use ExUnit.Case, async: true

  import Ecto.Query, only: [from: 2]

  describe "new/1" do
    test "raises an error when an invalid queryable is given" do
      assert_raise ArgumentError,
                   "expected a term implementing the Ecto.Queryable protocol, got: 1",
                   fn ->
                     Kino.Ecto.new(1, Repo)
                   end
    end
  end

  defmodule MockRepo do
    # Allows tests to verify or refute that a query was run
    # and also substitute the final result

    def all(query, opts \\ []) do
      report_call([__MODULE__, :all, query: query, opts: opts])
    end

    def aggregate(query, :count, opts \\ []) do
      report_call([__MODULE__, :aggregate, query: query, aggregate: :count, opts: opts])
    end

    # Test API

    @report_to :repo_report_to

    # Subscribes the caller to call info messages
    def subscribe() do
      Process.register(self(), @report_to)
    end

    # Reports call info to the subscriber and waits for resolution message
    defp report_call(info) do
      ref = make_ref()

      send(@report_to, {{self(), ref}, info})

      receive do
        {:resolve, ^ref, value} -> value
      after
        1_000 -> raise RuntimeError, "the following call hasn't been resolved: #{inspect(info)}"
      end
    end

    # Resolves the given call
    def resolve_call({pid, ref}, value) do
      send(pid, {:resolve, ref, value})
    end
  end

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field(:name, :string)

      timestamps()
    end
  end

  test "content contains columns definition if a schema is given" do
    widget = Kino.Ecto.new(User, MockRepo)

    MockRepo.subscribe()
    async_connect_self(widget)
    resolve_table_queries(MockRepo, [])
    data = await_connect_self()

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":id"},
                 %{key: "1", label: ":name"},
                 %{key: "2", label: ":inserted_at"},
                 %{key: "3", label: ":updated_at"}
               ],
               rows: []
             }
           } = data
  end

  test "connect contains columns definition if a query with schema source is given" do
    query = from(u in User, where: like(u.name, "%Jake%"))
    widget = Kino.Ecto.new(query, MockRepo)

    MockRepo.subscribe()
    async_connect_self(widget)
    resolve_table_queries(MockRepo, [])
    data = await_connect_self()

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":id"},
                 %{key: "1", label: ":name"},
                 %{key: "2", label: ":inserted_at"},
                 %{key: "3", label: ":updated_at"}
               ],
               rows: []
             }
           } = data
  end

  test "content contains empty columns if a query without schema is given and there are no rows" do
    query = from(u in "users", where: like(u.name, "%Jake%"))
    widget = Kino.Ecto.new(query, MockRepo)

    MockRepo.subscribe()
    async_connect_self(widget)
    resolve_table_queries(MockRepo, [])
    data = await_connect_self()

    assert %{content: %{columns: [], rows: []}} = data
  end

  test "sorting is enabled when a regular query is given" do
    query = from(u in User, where: like(u.name, "%Jake%"))
    widget = Kino.Ecto.new(query, MockRepo)

    MockRepo.subscribe()
    async_connect_self(widget)
    resolve_table_queries(MockRepo, [])
    data = await_connect_self()

    assert %{features: [:refetch, :pagination, :sorting]} = data
  end

  test "sorting is disabled when a query with custom select is given" do
    query = from(u in User, where: like(u.name, "%Jake%"), select: {u.id, u.name})
    widget = Kino.Ecto.new(query, MockRepo)

    MockRepo.subscribe()
    async_connect_self(widget)
    resolve_table_queries(MockRepo, [])
    data = await_connect_self()

    assert %{features: [:refetch, :pagination]} = data
  end

  test "returns rows received from repo" do
    widget = Kino.Ecto.new(User, MockRepo)

    users = [
      %User{
        id: 1,
        name: "Amy Santiago",
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      },
      %User{
        id: 2,
        name: "Jake Peralta",
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      },
      %User{
        id: 3,
        name: "Terry Jeffords",
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }
    ]

    MockRepo.subscribe()
    async_connect_self(widget)
    resolve_table_queries(MockRepo, users)
    data = await_connect_self()

    assert %{
             name: "users",
             features: _features,
             content: %{
               columns: [
                 %{key: "0", label: ":id"},
                 %{key: "1", label: ":name"},
                 %{key: "2", label: ":inserted_at"},
                 %{key: "3", label: ":updated_at"}
               ],
               rows: [
                 %{fields: %{"0" => "1", "1" => ~s/"Amy Santiago"/, "2" => _, "3" => _}},
                 %{fields: %{"0" => "2", "1" => ~s/"Jake Peralta"/, "2" => _, "3" => _}},
                 %{fields: %{"0" => "3", "1" => ~s/"Terry Jeffords"/, "2" => _, "3" => _}}
               ],
               page: 1,
               max_page: 1,
               order_by: nil,
               order: :asc
             }
           } = data
  end

  test "query limit and offset are overridden" do
    query = from(u in User, offset: 2, limit: 2)
    widget = Kino.Ecto.new(query, MockRepo)

    MockRepo.subscribe()
    async_connect_self(widget)
    %{all_query: %{offset: offset, limit: limit}} = resolve_table_queries(MockRepo, [])

    assert Macro.to_string(offset.expr) == "^0"
    assert offset.params == [{0, :integer}]
    assert Macro.to_string(limit.expr) == "^0"
    assert limit.params == [{10, :integer}]
  end

  test "query order by is kept if request doesn't specify any" do
    query = from(u in User, order_by: u.name)
    widget = Kino.Ecto.new(query, MockRepo)

    MockRepo.subscribe()
    async_connect_self(widget)
    %{all_query: %{order_bys: [order_by]}} = resolve_table_queries(MockRepo, [])

    assert Macro.to_string(order_by.expr) == "[asc: &0.name()]"
  end

  test "query order by is overridden if specified in the request" do
    query = from(u in User, order_by: u.name)
    widget = Kino.Ecto.new(query, MockRepo)

    MockRepo.subscribe()
    async_connect_self(widget)
    resolve_table_queries(MockRepo, [])

    send(
      widget.pid,
      {:event, "order_by", %{"key" => "0", "order" => "desc"}, %{origin: self()}}
    )

    %{all_query: %{order_bys: [order_by]}} = resolve_table_queries(MockRepo, [])

    assert Macro.to_string(order_by.expr) == "[desc: &0.id()]"
  end

  test "handles custom select results" do
    query = from(u in User, select: {u.id, u.name})
    widget = Kino.Ecto.new(query, MockRepo)

    results = [{1, "Amy Santiago"}, {2, "Jake Peralta"}]

    MockRepo.subscribe()
    async_connect_self(widget)
    resolve_table_queries(MockRepo, results)
    data = await_connect_self()

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: "0"},
                 %{key: "1", label: "1"}
               ],
               rows: [
                 %{fields: %{"0" => "1", "1" => ~s/"Amy Santiago"/}},
                 %{fields: %{"0" => "2", "1" => ~s/"Jake Peralta"/}}
               ]
             }
           } = data
  end

  test "handles a list of atomic items" do
    query = from(u in User, select: u.name)
    widget = Kino.Ecto.new(query, MockRepo)

    results = ["Amy Santiago", "Jake Peralta"]

    MockRepo.subscribe()
    async_connect_self(widget)
    resolve_table_queries(MockRepo, results)
    data = await_connect_self()

    assert %{
             content: %{
               columns: [
                 %{key: "0", label: ":item"}
               ],
               rows: [
                 %{fields: %{"0" => ~s/"Amy Santiago"/}},
                 %{fields: %{"0" => ~s/"Jake Peralta"/}}
               ]
             }
           } = data
  end

  defp async_connect_self(widget) do
    send(widget.pid, {:connect, self(), %{origin: self()}})
  end

  defp await_connect_self() do
    assert_receive {:connect_reply, %{} = data, %{}}
    data
  end

  defp resolve_table_queries(repo, results) do
    assert_receive {from, [^repo, :aggregate, query: count_query, aggregate: :count, opts: []]}
    MockRepo.resolve_call(from, length(results))

    assert_receive {from, [^repo, :all, query: all_query, opts: []]}
    MockRepo.resolve_call(from, results)

    %{count_query: count_query, all_query: all_query}
  end
end
