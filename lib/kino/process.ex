defmodule Kino.Process do
  @moduledoc """
  This module contains kinos for generating visualizations to help
  introspect your running processes.
  """

  alias Kino.Mermaid
  alias Kino.Process.Tracer

  @mermaid_classdefs """
  classDef root fill:#c4b5fd, stroke:#374151, stroke-width:4px, line-height:1.5em;
  classDef supervisor fill:#c4b5fd, stroke:#374151, stroke-width:1px, line-height:1.5em;
  classDef worker fill:#66c2a5, stroke:#374151, stroke-width:1px, line-height:1.5em;
  classDef notstarted color:#777, fill:#d9d9d9, stroke:#777, stroke-width:1px, line-height:1.5em;
  classDef ets fill:#a5f3fc, stroke:#374151, stroke-width:1px;
  """

  @type supervisor :: pid() | atom()
  @type trace_target :: :all | pid() | [pid()]
  @type label_response :: {:ok, String.t()} | :continue

  @doc """
  Generates a visualization of an application tree.

  Given the name of an application as an atom, this function will render the
  application tree. It is displayed with solid lines denoting supervisor-worker
  relationships and dotted lines denoting links between processes. The graph
  rendering supports the following options:

  ## Options

    * `:direction` - defines the direction of the graph visual. The
      value can either be `:top_down` or `:left_right`. Defaults to `:top_down`.

    * `:render_ets_tables` - determines whether ETS tables associated with the
      supervision tree are rendered. Defaults to `false`.

    * `:caption` - an optional caption for the diagram. Either a custom
      caption as string, or `nil` to disable the default caption.

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
  @spec app_tree(atom() | {atom(), node()}, keyword()) :: Mermaid.t()
  def app_tree(application, opts \\ []) do
    {application, node} =
      case application do
        application when is_atom(application) -> {application, node()}
        {application, node} when is_atom(application) and is_atom(node) -> {application, node}
      end

    {master, root_supervisor} =
      case :erpc.call(node, :application_controller, :get_master, [application]) do
        :undefined ->
          if Application.spec(application, :vsn) do
            raise ArgumentError,
                  "the provided application #{inspect(application)} does not have a supervision tree"
          else
            raise ArgumentError, "there is no application named #{inspect(application)}"
          end

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
    edges = traverse_supervisor(root_supervisor, opts)

    {:dictionary, dictionary} = process_info(root_supervisor, :dictionary)
    [ancestor] = dictionary[:"$ancestors"]

    caption = Keyword.get(opts, :caption, "Application tree for #{inspect(application)}")

    Mermaid.new(
      """
      graph #{direction};
      application_master(#{inspect(master)}):::supervisor ---> supervisor_ancestor;
      supervisor_ancestor(#{inspect(ancestor)}):::supervisor ---> 0;
      #{edges}
      #{@mermaid_classdefs}
      """,
      caption: caption
    )
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

    * `:caption` - an optional caption for the diagram. Either a custom
      caption as string, or `nil` to disable the default caption.

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
  @spec sup_tree(supervisor() | {supervisor(), node()}, keyword()) :: Mermaid.t()
  def sup_tree(supervisor, opts \\ []) do
    direction = direction_from_opts(opts)

    supervisor_pid =
      supervisor
      |> case do
        {name, node} -> :erpc.call(node, GenServer, :whereis, [name])
        supervisor -> GenServer.whereis(supervisor)
      end
      |> case do
        supervisor_pid when is_pid(supervisor_pid) ->
          supervisor_pid

        _ ->
          raise ArgumentError,
                "the provided identifier #{inspect(supervisor)} does not reference a running process"
      end

    edges = traverse_supervisor(supervisor_pid, opts)

    caption = Keyword.get(opts, :caption, "Supervisor tree for #{inspect(supervisor)}")

    Mermaid.new(
      """
      graph #{direction};
      #{edges}
      #{@mermaid_classdefs}
      """,
      caption: caption
    )
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
  @spec render_seq_trace(trace_target(), (-> any())) :: any()
  def render_seq_trace(trace_target \\ :all, trace_function, opts \\ []) do
    {func_result, sequence_diagram} = seq_trace(trace_target, trace_function, opts)
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

  ## Options

    * `:message_label` - A function to help label message events. If
      the given function returns `:continue`, then the default label
      is used. However, if the function returns a `String.t()`, then
      that will be used for the label.

    * `:caption` - an optional caption for the diagram. Either a custom
      caption as string, or `nil` to disable the default caption.

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

  Further if you are interested in custom labeling between messages
  sent between processes, you can specify custom labels for the
  messages you are interested in:

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
      end,
      message_label: fn(msg) ->
        case msg do
          {:"$gen_call", _ref, {:get, _}} -> {:ok, "GET: value"}
          _ -> :continue
        end
    end)
  """
  @spec seq_trace(trace_target(), (-> any()), keyword()) :: {any(), Mermaid.t()}
  def seq_trace(trace_target \\ :all, trace_function, opts \\ [])

  def seq_trace(pid, trace_function, opts) when is_pid(pid) do
    seq_trace([pid], trace_function, opts)
  end

  def seq_trace(trace_pids, trace_function, opts)
      when is_list(trace_pids) or trace_pids == :all do
    # Set up the process message tracer and the Erlang seq_trace_module
    calling_pid = self()
    {:ok, tracer_pid} = Tracer.start_link()
    :seq_trace.set_token(:send, true)
    :seq_trace.set_token(:receive, true)
    :seq_trace.set_token(:monotonic_timestamp, true)
    previous_tracer = :seq_trace.set_system_tracer(tracer_pid)

    # Run the user supplied function and capture the events if no errors were encountered
    {%{raw_trace_events: raw_trace_events, process_labels: process_labels}, func_result} =
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

        {Tracer.get_trace_info(tracer_pid), func_result}
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
          process_label = Map.get(process_labels, pid, :undefined)
          generate_participant_entry(pid, idx, process_label)
        end
      end)

    # Generate the mermaid formatted list of message events
    {formatted_messages, _} =
      trace_events
      |> Enum.reduce({[], MapSet.new()}, fn %{from: from, to: to, message: message},
                                            {events, started_processes} ->
        events = [normalize_message(from, to, message, participants_lookup, opts) | events]

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

    caption = Keyword.get(opts, :caption, "Messages traced from #{inspect(trace_pids)}")

    sequence_diagram =
      Mermaid.new(
        """
        %%{init: {'themeCSS': '.actor:last-of-type:not(:only-of-type) {dominant-baseline: hanging;}'} }%%
        sequenceDiagram
        #{participants}
        #{messages}
        """,
        caption: caption
      )

    {func_result, sequence_diagram}
  end

  # TODO: use :proc_lib.get_label/1 once we require OTP 27
  if Code.ensure_loaded?(:proc_lib) and function_exported?(:proc_lib, :get_label, 1) do
    defp get_label(pid), do: :proc_lib.get_label(pid)
  else
    defp get_label(_pid), do: :undefined
  end

  defp generate_participant_entry(pid, idx, process_label) do
    try do
      {:registered_name, name} = process_info(pid, :registered_name)
      "participant #{idx} AS #{module_or_atom_to_string(name)};"
    rescue
      _ ->
        case process_label do
          :undefined ->
            "participant #{idx} AS #35;PID#{:erlang.pid_to_list(pid)};"

          process_label ->
            "participant #{idx} AS #{format_for_mermaid_participant_alias(pid, process_label)};"
        end
    end
  end

  defp format_for_mermaid_participant_alias(pid, process_label) do
    label = process_label |> inspect() |> String.replace(~s{"}, "")
    "#{label}<br/>#{:erlang.pid_to_list(pid)}"
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

  defp normalize_message(from, to, message, participants_lookup, opts)
       when is_map_key(participants_lookup, from) and is_map_key(participants_lookup, to) do
    formatted_message = label_from_message(message, label_from_options(opts))
    from_idx = participants_lookup[from]
    to_idx = participants_lookup[to]

    "#{from_idx}->>#{to_idx}: #{formatted_message}"
  end

  defp normalize_message(_, _, _, _, _), do: ""

  defp label_from_message(message, custom_label) do
    case custom_label.(message) do
      {:ok, response} ->
        response

      :continue ->
        case message do
          {:EXIT, _, reason} -> "EXIT: #{label_from_reason(reason)}"
          {:spawn_request, _, _, _, _, _, _, _} -> "SPAWN"
          {:DOWN, _, :process, _, reason} -> "DOWN: #{label_from_reason(reason)}"
          {:"$gen_call", _ref, value} -> "CALL: #{label_from_value(value)}"
          {:"$gen_cast", value} -> "CAST: #{label_from_value(value)}"
          value -> "INFO: #{label_from_value(value)}"
        end
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

  defp label_from_options(opts) do
    opts
    |> Keyword.get(:message_label, fn _message -> :continue end)
  end

  defp direction_from_opts(opts) do
    opts
    |> Keyword.get(:direction, :top_down)
    |> convert_direction()
  end

  defp traverse_supervisor(supervisor, opts) when is_pid(supervisor) do
    supervisor_children =
      try do
        Supervisor.which_children(supervisor)
      catch
        _, _ ->
          raise ArgumentError, "the provided process #{inspect(supervisor)} is not a supervisor"
      end

    root_node = graph_node(0, :root, supervisor, :supervisor)

    supervisor_children
    |> traverse_processes(root_node, {%{}, 1, %{root_node.pid => root_node}})
    |> maybe_traverse_ets_tables(opts)
    |> traverse_links()
    |> Enum.map_join("\n", fn {_pid_pair, edge} ->
      generate_mermaid_entry(edge)
    end)
  end

  defp convert_direction(:top_down), do: "TD"
  defp convert_direction(:left_right), do: "LR"

  defp convert_direction(invalid_direction),
    do: raise(ArgumentError, "expected a valid direction, got: #{inspect(invalid_direction)}")

  defp traverse_processes(
         [{id, :undefined, type, _} | rest],
         parent_node,
         {rels, idx, resource_keys}
       ) do
    child_node = graph_node(idx, id, :undefined, type)
    connection = graph_edge(parent_node, child_node, :supervisor)

    traverse_processes(rest, parent_node, {add_rel(rels, connection), idx + 1, resource_keys})
  end

  defp traverse_processes(
         [{id, pid, :supervisor, _} | rest],
         parent_node,
         {rels, idx, resource_keys}
       ) do
    child_node = graph_node(idx, id, pid, :supervisor)
    connection = graph_edge(parent_node, child_node, :supervisor)
    resource_keys = Map.put(resource_keys, pid, child_node)

    children = Supervisor.which_children(pid)

    {subtree_rels, idx, resource_keys} =
      traverse_processes(children, child_node, {%{}, idx + 1, resource_keys})

    updated_rels =
      rels
      |> add_rels(subtree_rels)
      |> add_rel(connection)

    traverse_processes(rest, parent_node, {updated_rels, idx, resource_keys})
  end

  defp traverse_processes(
         [{id, pid, :worker, _} | rest],
         parent_node,
         {rels, idx, resource_keys}
       ) do
    child_node = graph_node(idx, id, pid, :worker)
    connection = graph_edge(parent_node, child_node, :supervisor)
    resource_keys = Map.put(resource_keys, pid, child_node)

    traverse_processes(rest, parent_node, {add_rel(rels, connection), idx + 1, resource_keys})
  end

  defp traverse_processes([], _, acc) do
    acc
  end

  defp add_rels(rels, additional_rels) do
    Map.merge(rels, additional_rels, fn _key, edge_1, _edge_2 -> edge_1 end)
  end

  defp add_rel(rels, edge) do
    lookup = Enum.sort([edge.node_1.idx, edge.node_2.idx])

    Map.put_new(rels, lookup, edge)
  end

  defp traverse_links({rels, _idx, resource_keys}) do
    rels_with_links =
      Enum.reduce(resource_keys, rels, fn
        {pid, _idx}, rels_with_links when is_pid(pid) ->
          {:links, links} = process_info(pid, :links)

          Enum.reduce(links, rels_with_links, fn link_pid, acc ->
            add_new_links_to_acc(resource_keys, pid, link_pid, acc)
          end)

        _, rels_with_links ->
          rels_with_links
      end)

    rels_with_links
  end

  defp maybe_traverse_ets_tables(supervision_tree_data, opts) do
    if Keyword.get(opts, :render_ets_tables, false) do
      do_traverse_ets_tables(supervision_tree_data)
    else
      supervision_tree_data
    end
  end

  defp do_traverse_ets_tables(supervision_tree_data) do
    {ets_owner_map, ets_heir_map} =
      :ets.all()
      |> Enum.reduce({%{}, %{}}, fn table, {ets_owner_map, ets_heir_map} ->
        try do
          table_info =
            %{
              id: :ets.info(table, :id),
              name: :ets.info(table, :name),
              owner: :ets.info(table, :owner),
              heir: :ets.info(table, :heir),
              protection: :ets.info(table, :protection)
            }

          if table_info.heir == :none do
            {Map.put(ets_owner_map, table_info.owner, table_info), ets_heir_map}
          else
            {
              Map.put(ets_owner_map, table_info.owner, table_info),
              Map.put(ets_heir_map, table_info.heir, table_info)
            }
          end
        rescue
          _ -> {ets_owner_map, ets_heir_map}
        end
      end)

    supervision_tree_data_with_ets_owners =
      ets_owner_map
      |> Enum.reduce(supervision_tree_data, fn {ets_table_owner, table_info},
                                               {rels, next_idx, resource_keys} ->
        case Map.get(resource_keys, ets_table_owner) do
          nil ->
            {rels, next_idx, resource_keys}

          owner_process_info ->
            node_2 =
              graph_node(next_idx, table_info.name, nil, :ets, %{
                protection: table_info.protection
              })

            rel_info = graph_edge(owner_process_info, node_2, :ets)
            updated_rels = Map.put(rels, [owner_process_info.idx, next_idx], rel_info)
            updated_resource_keys = Map.put(resource_keys, table_info.id, node_2)

            {updated_rels, next_idx + 1, updated_resource_keys}
        end
      end)

    ets_heir_map
    |> Enum.reduce(supervision_tree_data_with_ets_owners, fn {ets_table_heir, table_info},
                                                             {rels, next_idx, resource_keys} ->
      with %{pid: _pid} = node_1 <- Map.get(resource_keys, table_info.id),
           %{pid: _pid} = node_2 <- Map.get(resource_keys, ets_table_heir) do
        rel_info = graph_edge(node_1, node_2, :heir)
        updated_rels = Map.put(rels, [node_1.idx, node_2.idx], rel_info)

        {updated_rels, next_idx, resource_keys}
      else
        _ ->
          {rels, next_idx, resource_keys}
      end
    end)
  end

  defp add_new_links_to_acc(resource_keys, pid, link_pid, acc) do
    case resource_keys do
      %{^pid => node_1, ^link_pid => node_2} ->
        add_rel(acc, graph_edge(node_1, node_2, :link))

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

  defp graph_node(idx, id, pid, type, meta \\ nil) do
    %{
      idx: idx,
      id: id,
      pid: pid,
      type: type,
      meta: meta
    }
  end

  defp generate_mermaid_entry(%{node_1: node_1, node_2: node_2, relationship: :link}) do
    "#{graph_node(node_1)} -..- #{graph_node(node_2)}"
  end

  defp generate_mermaid_entry(%{node_1: node_1, node_2: node_2, relationship: :supervisor}) do
    "#{graph_node(node_1)} ---> #{graph_node(node_2)}"
  end

  defp generate_mermaid_entry(%{node_1: node_1, node_2: node_2, relationship: :ets}) do
    "#{graph_node(node_1)} -- owner --> #{graph_node(node_2)}"
  end

  defp generate_mermaid_entry(%{node_1: node_1, node_2: node_2, relationship: :heir}) do
    "#{graph_node(node_1)} -. heir .-> #{graph_node(node_2)}"
  end

  defp graph_node(%{pid: :undefined, id: id, idx: idx}) do
    "#{idx}(id: #{inspect(id)}):::notstarted"
  end

  defp graph_node(%{idx: idx, id: id, meta: %{protection: protection}, type: :ets}) do
    "#{idx}[(\"`#{module_or_atom_to_string(id)}\n**_#{protection}_**`\")]:::ets"
  end

  defp graph_node(%{idx: idx, id: id, pid: pid, type: type}) do
    type =
      if idx == 0 do
        :root
      else
        type
      end

    display =
      case process_info(pid, :registered_name) do
        {:registered_name, []} ->
          case get_label(pid) do
            :undefined ->
              if idx == 0 or id == :undefined do
                inspect(pid)
              else
                # Use worker/supervisor id as label
                format_for_mermaid_graph_node(pid, id)
              end

            process_label ->
              format_for_mermaid_graph_node(pid, process_label)
          end

        {:registered_name, name} ->
          module_or_atom_to_string(name)
      end

    "#{idx}(#{display}):::#{type}"
  end

  defp format_for_mermaid_graph_node(pid, process_label) do
    pid_text = :erlang.pid_to_list(pid) |> List.to_string()

    label = process_label |> inspect() |> String.replace(~s{"}, "")

    format_as_mermaid_unicode_text("#{label}<br/>#{pid_text}")
  end

  # this is needed to use unicode inside node's text
  # (https://mermaid.js.org/syntax/flowchart.html#unicode-text)
  defp format_as_mermaid_unicode_text(node_text) do
    "\"#{node_text}\""
  end

  defp module_or_atom_to_string(atom) do
    case Atom.to_string(atom) do
      "Elixir." <> rest -> rest
      rest -> rest
    end
  end

  defp process_info(pid, spec) do
    :erpc.call(node(pid), Process, :info, [pid, spec])
  end
end
