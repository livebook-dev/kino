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
    initial_pid_lookup = Map.put(%{}, supervisor, 0)

    {edges, _, _} =
      supervisor
      |> Supervisor.which_children()
      |> traverse_processes(supervisor, {[], 1, initial_pid_lookup})
      |> traverse_links(supervisor)

    edges =
      Enum.map_join(edges, "\n", fn edge -> SupervisorGraphEdge.generate_mermaid_entry(edge) end)

    Kino.Markdown.new("""
    ```mermaid
    graph TD;
    #{edges}
    classDef root fill:#c4b5fd, stroke:#374151, stroke-width:4px;
    classDef supervisor fill:#c4b5fd, stroke:#374151, stroke-width:1px;
    classDef worker fill:#93c5fd, stroke:#374151, stroke-width:1px;
    ```
    """)
  end

  def generate_supervision_tree(invalid_pid) do
    raise ArgumentError, "expected a PID, got: #{inspect(invalid_pid)}"
  end

  defp traverse_processes([{_, pid, :supervisor, _} | rest], supervisor, {rels, idx, pid_keys}) do
    pid_keys = Map.put(pid_keys, pid, idx)
    children = Supervisor.which_children(pid)

    supervisor_node =
      pid_keys
      |> Map.get(supervisor)
      |> SupervisorGraphNode.new(supervisor, :supervisor)

    worker_node = SupervisorGraphNode.new(idx, pid, :supervisor)

    new_connection = SupervisorGraphEdge.new(supervisor_node, worker_node, :supervisor)

    {subtree_rels, idx, pid_keys} = traverse_processes(children, pid, {[], idx + 1, pid_keys})
    traverse_processes(rest, supervisor, {[new_connection | subtree_rels] ++ rels, idx, pid_keys})
  end

  defp traverse_processes([{_, pid, :worker, _} | rest], supervisor, {rels, idx, pid_keys}) do
    supervisor_node =
      pid_keys
      |> Map.get(supervisor)
      |> SupervisorGraphNode.new(supervisor, :supervisor)

    worker_node = SupervisorGraphNode.new(idx, pid, :worker)

    new_connection = SupervisorGraphEdge.new(supervisor_node, worker_node, :supervisor)

    traverse_processes(rest, supervisor, {[new_connection | rels], idx + 1, pid_keys})
  end

  defp traverse_processes([], _, acc) do
    acc
  end

  defp traverse_links({rels, _idx, pid_keys} = thing, supervisor) do
    thing
  end
end
