defmodule Kino.Bridge do
  @moduledoc false

  import Kernel, except: [send: 2]

  # This module encapsulates the communication with Livebook
  # achieved via the group leader. For the implementation of
  # that group leader see Livebook.Evaluator.IOProxy

  @type request_error :: :unsupported | :terminated

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
  @spec put_output(Kino.Output.t()) :: :ok | {:error, request_error()}
  def put_output(output) do
    with {:ok, reply} <- io_request({:livebook_put_output, output}), do: reply
  end

  @doc """
  Requests the current value of input with the given id.

  Note that the input must be known to Livebook, otherwise
  an error is returned.
  """
  @spec get_input_value(String.t()) :: {:ok, term()} | {:error, request_error()}
  def get_input_value(input_id) do
    with {:ok, reply} <- io_request({:livebook_get_input_value, input_id}) do
      case reply do
        {:ok, value} ->
          {:ok, value}

        {:error, :not_found} ->
          raise ArgumentError,
                "failed to read input value, no input found for id #{inspect(input_id)}"
      end
    end
  end

  @doc """
  Associates `object` with `pid`.

  Any monitoring added to `object` will be dispatched once
  all of its associated pids terminate or the associated
  cells reevaluate.

  See `monitor_object/3` to add a monitoring.
  """
  @spec reference_object(term(), pid()) :: :ok | {:error, request_error()}
  def reference_object(object, pid) do
    with {:ok, reply} <- io_request({:livebook_reference_object, object, pid}), do: reply
  end

  @doc """
  Monitors an existing object to send `payload` to `target`
  when all of its associated pids or the associated cells
  reevaluate.

  It must be called after at least one reference is added
  via `reference_object/2`.
  """
  @spec monitor_object(term(), Process.dest(), payload :: term()) ::
          :ok | {:error, request_error()}
  def monitor_object(object, destination, payload) do
    with {:ok, reply} <- io_request({:livebook_monitor_object, object, destination, payload}) do
      case reply do
        :ok ->
          :ok

        {:error, :bad_object} ->
          raise ArgumentError,
                "failed to monitor object #{inspect(object)}, at least one reference must be added via reference_object/2 first"
      end
    end
  end

  @doc """
  Broadcasts the given message in Livebook to interested parties.
  """
  @spec broadcast(String.t(), String.t(), term()) :: :ok | {:error, request_error()}
  def broadcast(topic, subtopic, message) do
    with {:ok, reply} <- io_request(:livebook_get_broadcast_target),
         {:ok, pid} <- reply do
      send(pid, {:runtime_broadcast, topic, subtopic, message})
      :ok
    end
  end

  @doc """
  Sends message to the given Livebook process.
  """
  @spec send(pid(), term()) :: :ok
  def send(pid, message) do
    # For now we send directly
    Kernel.send(pid, message)
    :ok
  end

  defp io_request(request) do
    gl = Process.group_leader()
    ref = Process.monitor(gl)

    Kernel.send(gl, {:io_request, self(), ref, request})

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
