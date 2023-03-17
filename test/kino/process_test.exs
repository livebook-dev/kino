defmodule Kino.ProcessTest do
  use ExUnit.Case, async: true

  describe "app_tree/2" do
    test "raises if there is no sup tree" do
      assert_raise ArgumentError,
                   "the provided application :stdlib does not have a supervision tree",
                   fn -> Kino.Process.app_tree(:stdlib) end
    end
  end

  describe "sup_tree/2" do
    test "shows supervision tree with children" do
      pid =
        start_supervised!(%{
          id: Supervisor,
          start:
            {Supervisor, :start_link,
             [
               [
                 {Agent, fn -> :ok end},
                 %{id: :child, start: {Agent, :start_link, [fn -> :ok end, [name: :agent_child]]}}
               ],
               [name: :supervisor_parent, strategy: :one_for_one]
             ]},
          restart: :temporary
        })

      [_, {_, agent, _, _}] = Supervisor.which_children(pid)

      content = Kino.Process.sup_tree(pid) |> mermaid()
      assert content =~ "0(supervisor_parent):::root ---> 1(agent_child):::worker"
      assert content =~ "0(supervisor_parent):::root ---> 2(#{inspect(agent)}):::worker"

      content = Kino.Process.sup_tree(:supervisor_parent) |> mermaid()
      assert content =~ "0(supervisor_parent):::root ---> 1(agent_child):::worker"
      assert content =~ "0(supervisor_parent):::root ---> 2(#{inspect(agent)}):::worker"
    end

    test "shows supervision tree with children alongside non-started children" do
      pid =
        start_supervised!(%{
          id: Supervisor,
          start:
            {Supervisor, :start_link,
             [
               [
                 {Agent, fn -> :ok end},
                 %{id: :not_started, start: {Function, :identity, [:ignore]}}
               ],
               [name: :supervisor_parent, strategy: :one_for_one]
             ]},
          restart: :temporary
        })

      [{:not_started, :undefined, _, _}, {_, agent, _, _}] = Supervisor.which_children(pid)

      content = Kino.Process.sup_tree(pid) |> mermaid()
      assert content =~ "0(supervisor_parent):::root ---> 1(id: :not_started):::notstarted"
      assert content =~ "0(supervisor_parent):::root ---> 2(#{inspect(agent)}):::worker"
    end

    test "raises if supervisor does not exist" do
      assert_raise ArgumentError,
                   ~r/the provided identifier :not_a_valid_supervisor does not reference a running process/,
                   fn -> Kino.Process.sup_tree(:not_a_valid_supervisor) end
    end
  end

  defp mermaid(%Kino.JS{ref: ref}) do
    send(Kino.JS.DataStore, {:connect, self(), %{origin: "client:#{inspect(self())}", ref: ref}})
    assert_receive {:connect_reply, data, %{ref: ^ref}}
    data
  end
end
