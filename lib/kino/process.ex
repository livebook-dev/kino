defmodule Kino.Process do
  @moduledoc """
  This module contains kinos for generating visualizations to help
  introspect your running processes.
  """

  alias Kino.Markdown
  alias Kino.Process.Tracer

  @type supervisor :: pid() | atom()
  @type trace_target :: :all | pid() | [pid()]

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

    Markdown.new("""
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

    Markdown.new("""
    ```mermaid
    graph #{direction};
    #{edges}
    classDef root fill:#c4b5fd, stroke:#374151, stroke-width:4px;
    classDef supervisor fill:#c4b5fd, stroke:#374151, stroke-width:1px;
    classDef worker fill:#93c5fd, stroke:#374151, stroke-width:1px;
    ```
    """)
  end

  @doc """
  Renders a visual of the provided application tree.

  This function renders an application tree much like `app_tree/2` with the difference
  being that this function can be called anywhere within the Livebook code block
  whereas `app_tree/2` must have its result be the last thing returned from the code
  block in order to render the visual. It supports the same options as `app_tree/2` as
  it delegates to that function to generate the visual.
  """
  @spec render_app_tree(atom(), keyword()) :: Kino.nothing()
  def render_app_tree(application, opts \\ []) do
    application
    |> app_tree(opts)
    |> Kino.render()

    Kino.nothing()
  end

  @doc """
  Renders a sequence diagram of process messages and returns the function result.

  This function renders a sequence diagram much like `seq_trace/2` with the difference
  being that this function can be called anywhere within the Livebook code block
  whereas `seq_trace/2` must have its result be the last thing returned from the code
  block in order to render the visual. In addition, this function returns the result
  from the provided trace function.
  """
  @spec render_seq_trace(trace_target(), (() -> any())) :: any()
  def render_seq_trace(trace_target \\ :all, trace_function) do
    {func_result, sequence_diagram} = seq_trace(trace_target, trace_function)
    Kino.render(sequence_diagram)
    func_result
  end

  @doc """
  Renders a visual of the provided supervision tree.

  This function renders a supervision tree much like `sup_tree/2` with the difference
  being that this function can be called anywhere within the Livebook code block
  whereas `sup_tree/2` must have its result be the last thing returned from the code
  block in order to render the visual. It supports the same options as `sup_tree/2` as
  it delegates to that function to generate the visual.
  """
  @spec render_sup_tree(supervisor(), keyword()) :: Kino.nothing()
  def render_sup_tree(supervisor, opts \\ []) do
    supervisor
    |> sup_tree(opts)
    |> Kino.render()

    Kino.nothing()
  end

  @doc """
  Generate a sequence diagram of process messages starting from `self()`.

  The provided function is executed and traced, with all the events sent to and
  received by the trace target processes rendered in a sequence diagram. The trace
  target argument can either be a single PID, a list of PIDs, or the atom `:all`
  depending on what messages you would like to retain in your trace.

  ## Examples

  To generate a trace of all the messages occurring during the execution of the
  provided function, you can do the following:

      Kino.Process.seq_trace(fn ->
        {:ok, agent_pid} = Agent.start_link(fn -> [] end)
        Process.monitor(agent_pid)

        1..2
        |> Task.async_stream(
          fn value ->
            Agent.get(agent_pid, fn value -> value end)
            100 * value
          end,
          max_concurrency: 3
        )
        |> Stream.run()

        Agent.stop(agent_pid)
      end)

  If you are only interested in messages being sent to or received by certain PIDs,
  you can filter the sequence diagram by specifying the PIDs that you are interested
  in:

      {:ok, agent_pid} = Agent.start_link(fn -> [] end)
      Process.monitor(agent_pid)

      Kino.Process.seq_trace(agent_pid, fn ->
        1..2
        |> Task.async_stream(
          fn value ->
            Agent.get(agent_pid, fn value -> value end)
            100 * value
          end,
          max_concurrency: 3
        )
        |> Stream.run()

        Agent.stop(agent_pid)
      end)
  """
  @spec seq_trace(trace_target(), (() -> any())) :: {any(), Markdown.t()}
  def seq_trace(trace_target \\ :all, trace_function)

  def seq_trace(pid, trace_function) when is_pid(pid) do
    seq_trace([pid], trace_function)
  end

  def seq_trace(trace_pids, trace_function) when is_list(trace_pids) or trace_pids == :all do
    # Set up the process message tracer and the Erlang seq_trace_module
    calling_pid = self()
    {:ok, tracer_pid} = Tracer.start_link()
    :seq_trace.set_token(:send, true)
    :seq_trace.set_token(:receive, true)
    :seq_trace.set_token(:monotonic_timestamp, true)
    previous_tracer = :seq_trace.set_system_tracer(tracer_pid)

    # Run the user supplied function and capture the events if no errors were encountered
    {raw_trace_events, func_result} =
      try do
        func_result =
          try do
            # Run the user provided function
            trace_function.()
          after
            # Reset all of the seq_trace options
            :seq_trace.set_system_tracer(previous_tracer)
            :seq_trace.reset_trace()
          end

        {Tracer.get_trace_events(tracer_pid), func_result}
      after
        # The Tracer GenServer is no longer needed, shut it down
        GenServer.stop(tracer_pid)
      end

    # Get all of the events from the Tracer GenServer
    trace_events =
      raw_trace_events
      |> Enum.filter(fn
        # Skip :spawn_reply messages
        %{message: {:spawn_reply, _, _, _}} ->
          false

        # Skip loopback messages
        %{from: pid, to: pid} ->
          false

        # Filter out messages based on the trace target
        %{from: from_pid, to: to_pid} ->
          trace_pids == :all or from_pid in trace_pids or to_pid in trace_pids

        # Reject the rest
        _ ->
          false
      end)
      |> Enum.sort_by(fn %{timestamp: timestamp} ->
        timestamp
      end)

    # Get all the participating actors in the trace along with their sequence diagram IDs
    {participants_lookup, _idx} =
      Enum.reduce(trace_events, {%{}, 0}, fn %{from: from, to: to}, acc ->
        acc
        |> maybe_add_participant(from)
        |> maybe_add_participant(to)
      end)

    # Generate the Mermaid formatted list of participants
    participants =
      Enum.map_join(participants_lookup, "\n", fn {pid, idx} ->
        if pid == calling_pid do
          "participant #{idx} AS self();"
        else
          generate_participant_entry(pid, idx)
        end
      end)

    # Generate the mermaid formatted list of message events
    {formatted_messages, _} =
      trace_events
      |> Enum.reduce({[], MapSet.new()}, fn %{from: from, to: to, message: message},
                                            {events, started_processes} ->
        events = [normalize_message(from, to, message, participants_lookup) | events]

        from_idx = Map.get(participants_lookup, from, :not_found)
        to_idx = Map.get(participants_lookup, to, :not_found)

        cond do
          activate?(to_idx, message) ->
            {["activate #{to_idx}" | events], MapSet.put(started_processes, to_idx)}

          deactivate?(from_idx, message) and MapSet.member?(started_processes, from_idx) ->
            {["deactivate #{from_idx}" | events], MapSet.delete(started_processes, from_idx)}

          true ->
            {events, started_processes}
        end
      end)

    messages =
      formatted_messages
      |> Enum.reverse()
      |> Enum.join("\n")

    sequence_diagram =
      Markdown.new("""
      ```mermaid
      sequenceDiagram
      #{participants}
      #{messages}
      ```
      """)

    {func_result, sequence_diagram}
  end

  defp generate_participant_entry(pid, idx) do
    case Process.info(pid, :registered_name) do
      {:registered_name, name} when is_atom(name) ->
        "participant #{idx} AS #{inspect(name)};"

      _ ->
        "participant #{idx} AS #35;PID#{:erlang.pid_to_list(pid)};"
    end
  end

  defp maybe_add_participant({participants, idx}, pid) when is_pid(pid) do
    if Map.has_key?(participants, pid) do
      {participants, idx}
    else
      {Map.put(participants, pid, idx), idx + 1}
    end
  end

  defp maybe_add_participant(acc, _) do
    acc
  end

  defp activate?(idx, {:spawn_request, _, _, _, _, _, _, _}) when idx != :not_found, do: true
  defp activate?(_idx, _), do: false

  defp deactivate?(idx, {:EXIT, _, _}) when idx != :not_found, do: true
  defp deactivate?(_idx, _), do: false

  defp normalize_message(from, to, message, participants_lookup)
       when is_map_key(participants_lookup, from) and is_map_key(participants_lookup, to) do
    formatted_message = label_from_message(message)
    from_idx = participants_lookup[from]
    to_idx = participants_lookup[to]

    "#{from_idx}->>#{to_idx}: #{formatted_message}"
  end

  defp normalize_message(_, _, _, _), do: ""

  defp label_from_message(message) do
    case message do
      {:EXIT, _, reason} -> "EXIT: #{label_from_reason(reason)}"
      {:spawn_request, _, _, _, _, _, _, _} -> "SPAWN"
      {:DOWN, _, :process, _, reason} -> "DOWN: #{label_from_reason(reason)}"
      {:"$gen_call", _ref, value} -> "CALL: #{label_from_value(value)}"
      {:"$gen_cast", value} -> "CAST: #{label_from_value(value)}"
      value -> "INFO: #{label_from_value(value)}"
    end
  end

  defp label_from_reason(:normal), do: "normal"
  defp label_from_reason(:shutdown), do: "shutdown"
  defp label_from_reason({:shutdown, _}), do: "shutdown"
  defp label_from_reason(_), do: "abnormal"

  defp label_from_value(tuple)
       when is_tuple(tuple) and is_atom(elem(tuple, 0)),
       do: elem(tuple, 0)

  defp label_from_value(atom) when is_atom(atom), do: atom
  defp label_from_value(ref) when is_reference(ref), do: inspect(ref)
  defp label_from_value(tuple) when is_tuple(tuple), do: "tuple"
  defp label_from_value(_), do: "term"

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
