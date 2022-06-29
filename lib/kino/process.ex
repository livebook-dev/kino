defmodule Kino.Process do
  @moduledoc """
  This module contains kinos for generating visualizations to help
  introspect your running processes.
  """

  alias Kino.Markdown

  @type supervisor :: pid() | atom()

  @doc """
  Generates a visualization of an application tree.

  Given the name of an application as an atom, this function will render the
  application tree. It is displayed with solid lines denoting supervisor-worker
  relationships and dotted lines denoting links between processes. The graph
  rendering supports the following options:

  ## Options

    * `:direction` - defines the direction of the graph visual. The
      value can either be `:top_down` or `:left_right`. Defaults to `:top_down`.

  ## Examples

  To view the applications running in your instance run:

      :application_controller.which_applications()

  You can then call `Kino.Process.app_tree/1` to render
  the application tree using using the atom of the application.

      Kino.Process.app_tree(:logger)

  You can also change the direction of the rendering by calling
  `Kino.Process.app_tree/2` with the `:direction` option.

      Kino.Process.app_tree(:logger, direction: :left_right)
  """
  @spec app_tree(atom(), keyword()) :: Markdown.t()
  def app_tree(application, opts \\ []) when is_atom(application) do
    {master, root_supervisor} =
      case :application_controller.get_master(application) do
        :undefined ->
          raise ArgumentError,
                "the provided application #{inspect(application)} does not reference an application"

        master ->
          case :application_master.get_child(master) do
            {root, _application} when is_pid(root) ->
              {master, root}

            _ ->
              raise ArgumentError,
                    "the provided application #{inspect(application)} does not have a root supervisor"
          end
      end

    direction = direction_from_opts(opts)
    edges = traverse_supervisor(root_supervisor)

    {:dictionary, dictionary} = Process.info(root_supervisor, :dictionary)
    [ancestor] = dictionary[:"$ancestors"]

    Kino.Markdown.new("""
    ```mermaid
    graph #{direction};
    application_master(#{inspect(master)}):::supervisor ---> supervisor_ancestor;
    supervisor_ancestor(#{inspect(ancestor)}):::supervisor ---> 0;
    #{edges}
    classDef root fill:#c4b5fd, stroke:#374151, stroke-width:4px;
    classDef supervisor fill:#c4b5fd, stroke:#374151, stroke-width:1px;
    classDef worker fill:#93c5fd, stroke:#374151, stroke-width:1px;
    ```
    """)
  end

  @doc """
  Generates a visualization of a supervision tree.

  The provided supervisor can be either a named process or a PID. The supervision tree
  is displayed with solid lines denoting supervisor-worker relationships and dotted
  lines denoting links between processes. The graph rendering supports the following
  options:

  ## Options

    * `:direction` - defines the direction of the graph visual. The
      value can either be `:top_down` or `:left_right`. Defaults to `:top_down`.

  ## Examples

  With a supervisor definition like so:

      {:ok, supervisor_pid} =
        Supervisor.start_link(
          [
            {DynamicSupervisor, strategy: :one_for_one, name: MyApp.DynamicSupervisor},
            {Agent, fn -> [] end}
          ],
          strategy: :one_for_one,
          name: MyApp.Supervisor
        )

      Enum.each(1..3, fn _ ->
        DynamicSupervisor.start_child(MyApp.DynamicSupervisor, {Agent, fn -> %{} end})
      end)

  You can then call `Kino.Process.sup_tree/1` to render
  the supervision tree using using the PID of the supervisor.

      Kino.Process.sup_tree(supervisor_pid)

  You can also render the supervisor by passing the name of the supervisor
  if the supervisor was started with a name.

      Kino.Process.sup_tree(MyApp.Supervisor)

  You can also change the direction of the rendering by calling
  `Kino.Process.sup_tree/2` with the `:direction` option.

      Kino.Process.sup_tree(MyApp.Supervisor, direction: :left_right)
  """
  @spec sup_tree(supervisor(), keyword()) :: Markdown.t()
  def sup_tree(supervisor, opts \\ []) do
    direction = direction_from_opts(opts)
    edges = traverse_supervisor(supervisor)

    Kino.Markdown.new("""
    ```mermaid
    graph #{direction};
    #{edges}
    classDef root fill:#c4b5fd, stroke:#374151, stroke-width:4px;
    classDef supervisor fill:#c4b5fd, stroke:#374151, stroke-width:1px;
    classDef worker fill:#93c5fd, stroke:#374151, stroke-width:1px;
    ```
    """)
  end

  defp direction_from_opts(opts) do
    opts
    |> Keyword.get(:direction, :top_down)
    |> convert_direction()
  end

  defp traverse_supervisor(supervisor) do
    supervisor =
      case GenServer.whereis(supervisor) do
        supervisor_pid when is_pid(supervisor_pid) ->
          supervisor_pid

        _ ->
          raise ArgumentError,
                "the provided identifier #{inspect(supervisor)} does not reference a running process"
      end

    supervisor_children =
      try do
        Supervisor.which_children(supervisor)
      catch
        _, _ ->
          raise ArgumentError, "the provided process #{inspect(supervisor)} is not a supervisor"
      end

    supervisor_children
    |> traverse_processes(supervisor, {%{}, 1, %{supervisor => {0, :supervisor}}})
    |> traverse_links()
    |> Enum.map_join("\n", fn {_pid_pair, edge} ->
      generate_mermaid_entry(edge)
    end)
  end

  defp convert_direction(:top_down), do: "TD"
  defp convert_direction(:left_right), do: "LR"

  defp convert_direction(invalid_direction),
    do: raise(ArgumentError, "expected a valid direction, got: #{inspect(invalid_direction)}")

  defp traverse_processes([{_, pid, :supervisor, _} | rest], supervisor, {rels, idx, pid_keys}) do
    pid_keys = Map.put(pid_keys, pid, {idx, :supervisor})
    children = Supervisor.which_children(pid)

    {supervisor_idx, _type} = Map.get(pid_keys, supervisor)
    supervisor_node = graph_node(supervisor_idx, supervisor, :supervisor)

    worker_node = graph_node(idx, pid, :supervisor)
    new_connection = graph_edge(supervisor_node, worker_node, :supervisor)

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
    supervisor_node = graph_node(supervisor_idx, supervisor, :supervisor)

    worker_node = graph_node(idx, pid, :worker)
    new_connection = graph_edge(supervisor_node, worker_node, :supervisor)

    traverse_processes(rest, supervisor, {add_rel(rels, new_connection), idx + 1, pid_keys})
  end

  defp traverse_processes([], _, acc) do
    acc
  end

  defp add_rels(rels, additional_rels) do
    Map.merge(rels, additional_rels, fn _key, edge_1, _edge_2 -> edge_1 end)
  end

  defp add_rel(rels, edge) do
    lookup = Enum.sort([edge.node_1.pid, edge.node_2.pid])

    Map.put_new(rels, lookup, edge)
  end

  defp traverse_links({rels, _idx, pid_keys}) do
    rels_with_links =
      Enum.reduce(pid_keys, rels, fn {pid, _idx}, rels_with_links ->
        {:links, links} = Process.info(pid, :links)

        Enum.reduce(links, rels_with_links, fn link, acc ->
          add_new_links_to_acc(pid_keys, pid, link, acc)
        end)
      end)

    rels_with_links
  end

  defp add_new_links_to_acc(pid_keys, pid, link_pid, acc) do
    case pid_keys do
      %{^pid => {idx_1, type_1}, ^link_pid => {idx_2, type_2}} ->
        process_1 = graph_node(idx_1, pid, type_1)
        process_2 = graph_node(idx_2, link_pid, type_2)
        link_edge = graph_edge(process_1, process_2, :link)

        add_rel(acc, link_edge)

      _ ->
        acc
    end
  end

  # Mermaid rendering helper functions

  defp graph_edge(node_1, node_2, relationship) do
    %{
      node_1: node_1,
      node_2: node_2,
      relationship: relationship
    }
  end

  defp graph_node(id, pid, type) do
    %{
      id: id,
      pid: pid,
      type: type
    }
  end

  defp generate_mermaid_entry(%{node_1: node_1, node_2: node_2, relationship: :link}) do
    "#{graph_node(node_1)} -..- #{graph_node(node_2)}"
  end

  defp generate_mermaid_entry(%{node_1: node_1, node_2: node_2, relationship: :supervisor}) do
    "#{graph_node(node_1)} ---> #{graph_node(node_2)}"
  end

  defp graph_node(%{id: id, pid: pid, type: type}) do
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
