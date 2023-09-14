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
  Sends the given output as intermediate evaluation result directly
  to a specific client.
  """
  @spec put_output_to(term(), Kino.Output.t()) :: :ok | {:error, request_error()}
  def put_output_to(client_id, output) do
    with {:ok, reply} <- io_request({:livebook_put_output_to, client_id, output}), do: reply
  end

  @doc """
  Sends the given output as intermediate evaluation result directly
  to all connected client.
  """
  @spec put_output_to_clients(Kino.Output.t()) :: :ok | {:error, request_error()}
  def put_output_to_clients(output) do
    io_request_result =
      with {:error, :unsupported} <-
             io_request({:livebook_put_output_to_clients, output}),
           # Livebook v0.8.0 doesn't support direct clients output,
           # so we fallback to a regular one
           do: io_request({:livebook_put_output, output})

    with {:ok, reply} <- io_request_result, do: reply
  end

  @doc """
  Requests the current value of input with the given id.

  Note that the input must be known to Livebook, otherwise
  an error is returned.
  """
  @spec get_input_value(String.t()) :: {:ok, term()} | {:error, request_error() | :not_found}
  def get_input_value(input_id) do
    with {:ok, reply} <- io_request({:livebook_get_input_value, input_id}), do: reply
  end

  @doc """
  Requests the file path for the given file id.
  """
  @spec get_file_path({:file, String.t()}) ::
          {:ok, term()} | {:error, request_error() | :not_found}
  def get_file_path(file_ref) do
    with {:ok, reply} <- io_request({:livebook_get_file_path, file_ref}), do: reply
  end

  @doc """
  Requests the file path for notebook file with the given name.
  """
  @spec get_file_entry_path(String.t()) ::
          {:ok, term()} | {:error, request_error() | :forbidden | String.t()}
  def get_file_entry_path(name) do
    with {:ok, reply} <- io_request({:livebook_get_file_entry_path, name}), do: reply
  end

  @doc """
  Requests the file spec for notebook file with the given name.
  """
  @spec get_file_entry_spec(String.t()) ::
          {:ok, term()} | {:error, request_error() | :forbidden | String.t()}
  def get_file_entry_spec(name) do
    with {:ok, reply} <- io_request({:livebook_get_file_entry_spec, name}), do: reply
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

  ## Options

    * `:ack?` - whether the monitoring process wants to
      acknowledge the monitor message. When set to `true`
      the process receives `{payload, reply_to, reply_as}`
      and should do `send(reply_to, reply_as)` once it is
      done. This is useful when cleaning state after the
      object is removed, because Livebook waits for the
      acknowledgement before staring new evaluation.
      Defaults to `false`

  """
  @spec monitor_object(term(), Process.dest(), payload :: term(), keyword()) ::
          :ok | {:error, request_error()}
  def monitor_object(object, destination, payload, opts \\ []) do
    ack? = Keyword.get(opts, :ack?, false)

    io_request_result =
      with {:error, :unsupported} <-
             io_request({:livebook_monitor_object, object, destination, payload, ack?}),
           # Used until Livebook v0.7
           do: io_request({:livebook_monitor_object, object, destination, payload})

    with {:ok, reply} <- io_request_result do
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

  @doc """
  Starts monitoring the given Livebook process.

  Provides the same semantics as `Process.monitor/1`.
  """
  @spec monitor(pid()) :: reference()
  def monitor(pid) do
    Process.monitor(pid)
  end

  @doc """
  Returns the file that is currently being evaluated.
  """
  @spec get_evaluation_file() :: String.t()
  def get_evaluation_file() do
    case io_request(:livebook_get_evaluation_file) do
      {:ok, file} -> file
      {:error, _} -> "nofile"
    end
  end

  @doc """
  Returns information about the running app.
  """
  @spec get_app_info() :: {:ok, map()} | {:error, request_error()}
  def get_app_info() do
    with {:ok, reply} <- io_request(:livebook_get_app_info), do: reply
  end

  @doc """
  Returns a temporary directory tied to the current runtime.
  """
  @spec get_tmp_dir() :: {:ok, String.t()} | {:error, request_error() | :not_available}
  def get_tmp_dir() do
    with {:ok, reply} <- io_request(:livebook_get_tmp_dir), do: reply
  end

  @doc """
  Checks if the caller is running within Livebook context (group leader).
  """
  @spec within_livebook?() :: boolean()
  def within_livebook?() do
    # We make a Livebook-specific side-effect-free request and see if
    # it is recognized
    match?({:ok, _}, io_request(:livebook_get_evaluation_file))
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
