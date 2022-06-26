defmodule Kino.Process do
  @moduledoc """

  ## Examples
  """

  defmodule SupervisorGraphNode do
    @moduledoc false

    defstruct [:id, :pid, :type]

    @doc false
    def new(id, pid, type) do
      %__MODULE__{
        id: id,
        pid: pid,
        type: type
      }
    end

    @doc false
    def generate_node(%__MODULE__{id: id, pid: pid, type: type}) do
      type =
        if id == 0 do
          :root
        else
          type
        end

      display =
        pid
        |> Process.info(:registered_name)
        |> case do
          {:registered_name, []} -> inspect(pid)
          {:registered_name, name} -> inspect(name)
        end

      "#{id}(#{display}):::#{type}"
    end
  end

  defmodule SupervisorGraphEdge do
    @moduledoc false

    defstruct [:node_1, :node_2, :relationship]

    @doc false
    def new(node_1, node_2, relationship) do
      %__MODULE__{
        node_1: node_1,
        node_2: node_2,
        relationship: relationship
      }
    end

    @doc false
    def generate_mermaid_entry(%__MODULE__{node_1: node_1, node_2: node_2, relationship: :link}) do
      "#{SupervisorGraphNode.generate_node(node_1)} -..- #{SupervisorGraphNode.generate_node(node_2)}"
    end

    def generate_mermaid_entry(%__MODULE__{
          node_1: node_1,
          node_2: node_2,
          relationship: :supervisor
        }) do
      "#{SupervisorGraphNode.generate_node(node_1)} ---> #{SupervisorGraphNode.generate_node(node_2)}"
    end
  end

  @doc """
  Generates a Mermaid.js graph of the supervision tree
  """
  @spec generate_supervision_tree(pid()) :: Kino.Markdown.t()
  def generate_supervision_tree(supervisor) when is_pid(supervisor) do
    try do
      initial_pid_lookup = Map.put(%{}, supervisor, {0, :supervisor})

      {edges, _, _} =
        supervisor
        |> Supervisor.which_children()
        |> traverse_processes(supervisor, {%{}, 1, initial_pid_lookup})
        |> traverse_links()

      edges =
        edges
        |> Enum.map_join("\n", fn {_pid_pair, edge} ->
          SupervisorGraphEdge.generate_mermaid_entry(edge)
        end)

      Kino.Markdown.new("""
      ```mermaid
      graph TD;
      #{edges}
      classDef root fill:#c4b5fd, stroke:#374151, stroke-width:4px;
      classDef supervisor fill:#c4b5fd, stroke:#374151, stroke-width:1px;
      classDef worker fill:#93c5fd, stroke:#374151, stroke-width:1px;
      ```
      """)
    catch
      _, _ ->
        raise ArgumentError, "the provided PID #{inspect(supervisor)} is not a supervisor"
    end
  end

  def generate_supervision_tree(invalid_pid) do
    raise ArgumentError, "expected a PID, got: #{inspect(invalid_pid)}"
  end

  defp traverse_processes([{_, pid, :supervisor, _} | rest], supervisor, {rels, idx, pid_keys}) do
    pid_keys = Map.put(pid_keys, pid, {idx, :supervisor})
    children = Supervisor.which_children(pid)

    {supervisor_idx, _type} = Map.get(pid_keys, supervisor)
    supervisor_node = SupervisorGraphNode.new(supervisor_idx, supervisor, :supervisor)

    worker_node = SupervisorGraphNode.new(idx, pid, :supervisor)
    new_connection = SupervisorGraphEdge.new(supervisor_node, worker_node, :supervisor)

    {subtree_rels, idx, pid_keys} = traverse_processes(children, pid, {%{}, idx + 1, pid_keys})

    updated_rels =
      rels
      |> add_rels(subtree_rels)
      |> add_rel(new_connection)

    traverse_processes(rest, supervisor, {updated_rels, idx, pid_keys})
  end

  defp traverse_processes([{_, pid, :worker, _} | rest], supervisor, {rels, idx, pid_keys}) do
    pid_keys = Map.put(pid_keys, pid, {idx, :worker})

    {supervisor_idx, _type} = Map.get(pid_keys, supervisor)
    supervisor_node = SupervisorGraphNode.new(supervisor_idx, supervisor, :supervisor)

    worker_node = SupervisorGraphNode.new(idx, pid, :worker)
    new_connection = SupervisorGraphEdge.new(supervisor_node, worker_node, :supervisor)

    traverse_processes(rest, supervisor, {add_rel(rels, new_connection), idx + 1, pid_keys})
  end

  defp traverse_processes([], _, acc) do
    acc
  end

  defp add_rels(rels, additional_rels) do
    Map.merge(rels, additional_rels, fn _key, edge_1, _edge_2 -> edge_1 end)
  end

  defp add_rel(rels, %SupervisorGraphEdge{} = edge) do
    lookup = Enum.sort([edge.node_1.pid, edge.node_2.pid])

    Map.put_new(rels, lookup, edge)
  end

  defp traverse_links({rels, idx, pid_keys}) do
    rels_with_links =
      pid_keys
      |> Enum.reduce(rels, fn {pid, _idx}, rels_with_links ->
        {:links, links} = Process.info(pid, :links)

        links
        |> Enum.reduce(rels_with_links, fn link, acc ->
          add_new_links_to_acc(pid_keys, pid, link, acc)
        end)
      end)

    {rels_with_links, idx, pid_keys}
  end

  defp add_new_links_to_acc(pid_keys, pid, link_pid, acc) do
    with {:ok, {idx_1, type_1}} <- Map.fetch(pid_keys, pid),
         {:ok, {idx_2, type_2}} <- Map.fetch(pid_keys, link_pid) do
      process_1 = SupervisorGraphNode.new(idx_1, pid, type_1)
      process_2 = SupervisorGraphNode.new(idx_2, link_pid, type_2)
      link_edge = SupervisorGraphEdge.new(process_1, process_2, :link)

      add_rel(acc, link_edge)
    else
      _ ->
        acc
    end
  end
end
