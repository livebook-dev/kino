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
  def handle_info({{:terminate, pid}, reply_to, reply_as}, state) do
    DynamicSupervisor.terminate_child(Kino.DynamicSupervisor, pid)
    send(reply_to, reply_as)
    {:noreply, state}
  end
end
