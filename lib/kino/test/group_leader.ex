defmodule Kino.Test.GroupLeader do
  @moduledoc false

  # A process mocking the Livebook group leader,
  # for testing parts relying on Kino.Bridge.

  use GenServer

  @doc """
  Starts a new group leader.

  All messages that would be sent to Livebook are sent to
  `target` instead.
  """
  def start_link(target) do
    GenServer.start_link(__MODULE__, {target})
  end

  @impl true
  def init({target}) do
    {:ok, %{target: target}}
  end

  @impl true
  def handle_info({:io_request, from, reply_as, req}, state) do
    case io_request(req, state) do
      :forward ->
        send(Process.group_leader(), {:io_request, from, reply_as, req})

      reply ->
        send(from, {:io_reply, reply_as, reply})
    end

    {:noreply, state}
  end

  defp io_request({:livebook_put_output, output}, state) do
    send(state.target, {:livebook_put_output, output})
    :ok
  end

  defp io_request(:livebook_get_broadcast_target, state) do
    {:ok, state.target}
  end

  defp io_request(_request, _state) do
    # Forward everything else to the default group leader
    :forward
  end
end
