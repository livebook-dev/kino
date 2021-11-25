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

  defp io_request(request) do
    gl = Process.group_leader()
    ref = Process.monitor(gl)

    send(gl, {:io_request, self(), ref, request})

    result =
      receive do
        {:io_reply, ^ref, reply} -> {:ok, reply}
        {:DOWN, ^ref, :process, _object, _reason} -> {:error, :terminated}
      end

    Process.demonitor(ref, [:flush])

    result
  end
end
