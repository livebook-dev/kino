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

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field(:name, :string)

      timestamps()
    end
  end

  describe "connecting" do
    test "connect reply contains columns definition if a schema is given" do
      widget = Kino.Ecto.new(User, MockRepo)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply,
                      %{
                        name: "users",
                        columns: [
                          %{key: :id, label: ":id"},
                          %{key: :name, label: ":name"},
                          %{key: :inserted_at, label: ":inserted_at"},
                          %{key: :updated_at, label: ":updated_at"}
                        ],
                        features: _features
                      }}
    end

    test "connect reply contains columns definition if a query with schema source is given" do
      query = from(u in User, where: like(u.name, "%Jake%"))
      widget = Kino.Ecto.new(query, MockRepo)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply,
                      %{
                        name: "users",
                        columns: [
                          %{key: :id, label: ":id"},
                          %{key: :name, label: ":name"},
                          %{key: :inserted_at, label: ":inserted_at"},
                          %{key: :updated_at, label: ":updated_at"}
                        ],
                        features: _features
                      }}
    end

    test "connect reply contains empty columns if a query without schema is given" do
      query = from(u in "users", where: like(u.name, "%Jake%"))
      widget = Kino.Ecto.new(query, MockRepo)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply,
                      %{
                        name: "users",
                        columns: [],
                        features: _features
                      }}
    end

    test "connect reply contains empty columns if a query with custom select is given" do
      query = from(u in User, select: {u.id, u.name})
      widget = Kino.Ecto.new(query, MockRepo)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply,
                      %{
                        name: "users",
                        columns: [],
                        features: _features
                      }}
    end

    test "sorting is enabled when a regular query is given" do
      query = from(u in User, where: like(u.name, "%Jake%"))
      widget = Kino.Ecto.new(query, MockRepo)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply, %{features: [:refetch, :pagination, :sorting]}}
    end

    test "sorting is disabled when a query with custom select is given" do
      query = from(u in User, where: like(u.name, "%Jake%"), select: {u.id, u.name})
      widget = Kino.Ecto.new(query, MockRepo)

      send(widget.pid, {:connect, self()})

      assert_receive {:connect_reply, %{features: [:refetch, :pagination]}}
    end
  end

  defmodule MockRepo do
    @moduledoc false

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

  describe "querying rows" do
    test "returns rows received from repo" do
      widget = Kino.Ecto.new(User, MockRepo)
      connect_self(widget)

      spec = %{offset: 0, limit: 10, order_by: nil, order: :asc}

      MockRepo.subscribe()

      send(widget.pid, {:get_rows, self(), spec})

      assert_receive {from, [MockRepo, :aggregate, query: _, aggregate: :count, opts: []]}
      MockRepo.resolve_call(from, 3)

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

      assert_receive {from, [MockRepo, :all, query: _, opts: []]}
      MockRepo.resolve_call(from, users)

      assert_receive {:rows,
                      %{
                        rows: [
                          %{
                            id: _,
                            fields: %{
                              id: "1",
                              name: ~s/"Amy Santiago"/,
                              inserted_at: _,
                              updated_at: _
                            }
                          },
                          %{
                            id: _,
                            fields: %{
                              id: "2",
                              name: ~s/"Jake Peralta"/,
                              inserted_at: _,
                              updated_at: _
                            }
                          },
                          %{
                            id: _,
                            fields: %{
                              id: "3",
                              name: ~s/"Terry Jeffords"/,
                              inserted_at: _,
                              updated_at: _
                            }
                          }
                        ],
                        total_rows: 3,
                        columns: _columns
                      }}
    end

    test "query limit and offset are overridden" do
      query = from(u in User, offset: 2, limit: 2)
      widget = Kino.Ecto.new(query, MockRepo)
      connect_self(widget)

      spec = %{offset: 0, limit: 10, order_by: nil, order: :asc}

      MockRepo.subscribe()

      send(widget.pid, {:get_rows, self(), spec})

      assert_receive {from, [MockRepo, :aggregate, query: _, aggregate: :count, opts: []]}
      MockRepo.resolve_call(from, 3)

      assert_receive {_from, [MockRepo, :all, query: %{offset: offset, limit: limit}, opts: []]}
      assert Macro.to_string(offset.expr) == "^0"
      assert offset.params == [{0, :integer}]
      assert Macro.to_string(limit.expr) == "^0"
      assert limit.params == [{10, :integer}]
    end

    test "query order by is kept if request doesn't specify any" do
      query = from(u in User, order_by: u.name)
      widget = Kino.Ecto.new(query, MockRepo)
      connect_self(widget)

      spec = %{offset: 0, limit: 10, order_by: nil, order: :asc}

      MockRepo.subscribe()

      send(widget.pid, {:get_rows, self(), spec})

      assert_receive {from, [MockRepo, :aggregate, query: _, aggregate: :count, opts: []]}
      MockRepo.resolve_call(from, 3)

      assert_receive {_from, [MockRepo, :all, query: %{order_bys: [order_by]}, opts: []]}
      assert Macro.to_string(order_by.expr) == "[asc: &0.name()]"
    end

    test "query order by is overriden if specified in the request" do
      query = from(u in User, order_by: u.name)
      widget = Kino.Ecto.new(query, MockRepo)
      connect_self(widget)

      spec = %{offset: 0, limit: 10, order_by: :id, order: :desc}

      MockRepo.subscribe()

      send(widget.pid, {:get_rows, self(), spec})

      assert_receive {from, [MockRepo, :aggregate, query: _, aggregate: :count, opts: []]}
      MockRepo.resolve_call(from, 3)

      assert_receive {_from, [MockRepo, :all, query: %{order_bys: [order_by]}, opts: []]}
      assert Macro.to_string(order_by.expr) == "[desc: &0.id()]"
    end

    test "handles custom select results" do
      query = from(u in User, select: {u.id, u.name})
      widget = Kino.Ecto.new(query, MockRepo)
      connect_self(widget)

      spec = %{offset: 0, limit: 10, order_by: :id, order: :desc}

      MockRepo.subscribe()

      send(widget.pid, {:get_rows, self(), spec})

      assert_receive {from, [MockRepo, :aggregate, query: _, aggregate: :count, opts: []]}
      MockRepo.resolve_call(from, 3)

      data = [{1, "Amy Santiago"}, {2, "Jake Peralta"}]

      assert_receive {from, [MockRepo, :all, query: _, opts: []]}
      MockRepo.resolve_call(from, data)

      assert_receive {:rows,
                      %{
                        rows: [
                          %{id: _, fields: %{0 => "1", 1 => ~s/"Amy Santiago"/}},
                          %{id: _, fields: %{0 => "2", 1 => ~s/"Jake Peralta"/}}
                        ],
                        total_rows: 3,
                        columns: [
                          %{key: 0, label: "0"},
                          %{key: 1, label: "1"}
                        ]
                      }}
    end
  end

  defp connect_self(widget) do
    send(widget.pid, {:connect, self()})
    assert_receive {:connect_reply, %{}}
  end
end
