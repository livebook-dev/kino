defmodule Kino.Bridge do
  @moduledoc false

  # This module encapsulates the communication with Livebook
  # achieved via the group leader. For the implementation of
  # that group leader see Livebook.Evaluator.IOProxy

  @doc """
  Generates a unique, reevaluation-safe token.

  If obtaining the token fails, a unique term is returned
  instead.
  """
  @spec generate_token() :: term()
  def generate_token() do
    case io_request(:livebook_generate_token) do
      {:ok, token} -> token
      {:error, _} -> System.unique_integer()
    end
  end

  @doc """
  Sends the given output as intermediate evaluation result.
  """
  @spec put_output(Kino.Output.t()) :: :ok | {:error, atom()}
  def put_output(output) do
    with {:ok, reply} <- io_request({:livebook_put_output, output}), do: reply
  end

  @doc """
  Requests the current value of input with the given id.

  Note that the input must be known to Livebook, otherwise
  an error is returned.
  """
  @spec get_input_value(String.t()) :: {:ok, term()} | {:error, atom()}
  def get_input_value(input_id) do
    with {:ok, reply} <- io_request({:livebook_get_input_value, input_id}), do: reply
  end

  @doc """
  Adds the given process as a pointer to the given object.

  In most cases the parent process should be the caller.
  """
  @spec object_add_pointer(pid(), term(), pid()) :: :ok | {:error, atom()}
  def object_add_pointer(gl \\ Process.group_leader(), object_id, parent) do
    case io_request(gl, {:livebook_object_add_pointer, object_id, parent}) do
      {:ok, :ok} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Schedules `payload` to be send to `destination` when the object
  is released.
  """
  @spec object_monitor(pid(), term(), Process.dest(), payload :: term()) :: :ok | {:error, atom()}
  def object_monitor(gl \\ Process.group_leader(), object_id, destination, payload) do
    case io_request(gl, {:livebook_object_monitor, object_id, destination, payload}) do
      {:ok, :ok} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  defp io_request(gl \\ Process.group_leader(), request) do
    ref = Process.monitor(gl)

    send(gl, {:io_request, self(), ref, request})

    result =
      receive do
        {:io_reply, ^ref, {:error, {:request, _}}} -> {:error, :unsupported}
        {:io_reply, ^ref, {:error, :request}} -> {:error, :unsupported}
        {:io_reply, ^ref, reply} -> {:ok, reply}
        {:DOWN, ^ref, :process, _object, _reason} -> {:error, :terminated}
      end

    Process.demonitor(ref, [:flush])

    result
  end
end
