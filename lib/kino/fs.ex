defmodule Kino.FS do
  @moduledoc """
  Provides access to notebook files.
  """

  defmodule ForbiddenError do
    @moduledoc """
    Exception raised when access to a notebook file is forbidden.
    """

    defexception [:name]

    @impl true
    def message(exception) do
      "forbidden access to file #{inspect(exception.name)}"
    end
  end

  @doc """
  Accesses notebook file with the given name and returns a local path
  to read its contents from.

  This invocation may take a while, in case the file is downloaded
  from a URL and is not in the cache.

  > #### File operations {: .info}
  >
  > You should treat the file as read-only. To avoid unnecessary
  > copies the path may potentially be pointing to the original file,
  > in which case any write operations would be persisted. This
  > behaviour is not always the case, so you should not rely on it
  > either.
  """
  @spec file_path(String.t()) :: String.t()
  def file_path(name) when is_binary(name) do
    case Kino.Bridge.get_file_entry_path(name) do
      {:ok, path} ->
        path

      {:error, :forbidden} ->
        raise ForbiddenError, name: name

      {:error, message} ->
        raise message

      {:request_error, reason} ->
        raise "failed to access file path, reason: #{inspect(reason)}"
    end
  end

  @doc """
  Accesses notebook file with the given name and returns a specification
  of the file location.

  This does not copy any files and moves the responsibility of reading
  the file to the caller. If you need to read a file directly, use
  `file_path/1`.
  """
  @spec file_spec(String.t()) :: FSS.entry()
  def file_spec(name) do
    case Kino.Bridge.get_file_entry_spec(name) do
      {:ok, spec} ->
        file_spec_to_fss(spec)

      {:error, :forbidden} ->
        raise ForbiddenError, name: name

      {:error, message} ->
        raise message

      {:request_error, reason} ->
        raise "failed to access file spec, reason: #{inspect(reason)}"
    end
  end

  defp file_spec_to_fss(%{type: :local} = file_spec) do
    FSS.Local.from_path(file_spec.path)
  end

  defp file_spec_to_fss(%{type: :url} = file_spec) do
    case FSS.HTTP.parse(file_spec.url) do
      {:ok, entry} -> entry
      {:error, error} -> raise error
    end
  end

  defp file_spec_to_fss(%{type: :s3} = file_spec) do
    case FSS.S3.parse("s3:///" <> file_spec.key,
           config: [
             region: file_spec.region,
             endpoint: file_spec.bucket_url,
             access_key_id: file_spec.access_key_id,
             secret_access_key: file_spec.secret_access_key,
             # Token field is only available on Livebook v0.12 onwards
             token: Map.get(file_spec, :token)
           ]
         ) do
      {:ok, entry} -> entry
      {:error, error} -> raise error
    end
  end
end
