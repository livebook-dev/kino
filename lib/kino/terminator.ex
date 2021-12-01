defmodule Kino.Terminator do
  @moduledoc false

  # A process responsible for shutting down processes.

  use GenServer

  @name __MODULE__

  def cross_node_name() do
    {@name, node()}
  end

  @doc """
  Starts the terminator.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_info({:terminate, pid}, state) do
    :ok = DynamicSupervisor.terminate_child(Kino.DynamicSupervisor, pid)
    {:noreply, state}
  end
end
