defmodule Kino.JS.DataStore do
  @moduledoc false

  # Process responsible for keeping the data for static JS outputs.
  # Unlike JS.Live kinos, plain JS kinos have no server, so we use
  # a single process for storing their data and replying to data
  # queries.

  use GenServer

  @name __MODULE__

  def cross_node_name() do
    {@name, node()}
  end

  @doc """
  Starts the data store.
  """
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, {}, name: @name)
  end

  @doc """
  Stores output data under the given ref.
  """
  @spec store(Kino.Output.ref(), term(), function()) :: :ok
  def store(ref, data, export) do
    GenServer.cast(@name, {:store, ref, data, export})
  end

  @impl true
  def init({}) do
    {:ok, %{ref_with_data: %{}}}
  end

  @impl true
  def handle_cast({:store, ref, data, export}, state) do
    state = put_in(state.ref_with_data[ref], %{data: data, export: export, export_result: nil})
    {:noreply, state}
  end

  @impl true
  def handle_info({:connect, pid, %{origin: _origin, ref: ref}}, state) do
    with {:ok, %{data: data}} <- Map.fetch(state.ref_with_data, ref) do
      Kino.Bridge.send(pid, {:connect_reply, data, %{ref: ref}})
    end

    {:noreply, state}
  end

  def handle_info({:export, pid, %{ref: ref}}, state) do
    case state.ref_with_data do
      %{^ref => info} ->
        {state, export_result} =
          if info.export_result do
            {state, info.export_result}
          else
            export_result = info.export.(info.data)
            state = put_in(state.ref_with_data[ref].export_result, export_result)
            {state, export_result}
          end

        Kino.Bridge.send(pid, {:export_reply, export_result, %{ref: ref}})

        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:remove, ref}, state) do
    {_, state} = pop_in(state.ref_with_data[ref])
    {:noreply, state}
  end
end
