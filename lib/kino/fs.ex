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
end
