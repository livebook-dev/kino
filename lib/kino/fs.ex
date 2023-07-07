defmodule Kino.FS do
  @moduledoc """
  Provides access to notebook files.
  """

  @doc """
  Accesses notebook file with the given name and returns a local path
  to ead its contents from.

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

      {:error, message} when is_binary(message) ->
        raise message

      {:error, reason} when is_atom(reason) ->
        raise "failed to access file path, reason: #{inspect(reason)}"
    end
  end

  @typep file_spec ::
           %{
             type: :local,
             path: String.t()
           }
           | %{
               type: :url,
               url: String.t()
             }
           | %{
               type: :s3,
               bucket_url: String.t(),
               region: String.t(),
               access_key_id: String.t(),
               secret_access_key: String.t(),
               key: String.t()
             }

  @doc false
  @spec file_spec(String.t()) :: file_spec()
  def file_spec(name) do
    case Kino.Bridge.get_file_entry_spec(name) do
      {:ok, spec} ->
        spec

      {:error, message} when is_binary(message) ->
        raise message

      {:error, reason} when is_atom(reason) ->
        raise "failed to access file spec, reason: #{inspect(reason)}"
    end
  end
end
