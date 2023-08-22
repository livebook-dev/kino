defmodule Kino.FSTest do
  use ExUnit.Case, async: true

  describe "file_spec/1" do
    test "returns a file spec" do
      name = "file.txt"
      path = "/home/bob/file.txt"
      spec = %{type: :local, path: path}

      configure_gl_with_reply({:livebook_get_file_entry_spec, name}, {:ok, spec})

      assert %FSS.Local.Entry{path: ^path} = Kino.FS.file_spec(name)
    end

    test "returns an HTTP FSS entry" do
      name = "remote-file.txt"
      url = "https://example.com/remote-file.txt"
      spec = %{type: :url, url: url}

      configure_gl_with_reply({:livebook_get_file_entry_spec, name}, {:ok, spec})

      assert %FSS.HTTP.Entry{url: ^url, config: %FSS.HTTP.Config{headers: []}} =
               Kino.FS.file_spec(name)
    end

    test "returns a S3 FSS entry" do
      name = "file-from-s3.txt"
      bucket_url = "https://s3.us-west-1.amazonaws.com/my-bucket"

      spec = %{
        type: :s3,
        bucket_url: bucket_url,
        region: "us-west-1",
        access_key_id: "access-key-1",
        secret_access_key: "secret-access-key-1",
        key: "file-from-s3.txt"
      }

      configure_gl_with_reply({:livebook_get_file_entry_spec, name}, {:ok, spec})

      assert %FSS.S3.Entry{} = s3 = Kino.FS.file_spec(name)

      assert s3.key == spec.key

      assert s3.config.region == spec.region
      assert s3.config.endpoint == bucket_url
      assert s3.config.access_key_id == spec.access_key_id
      assert s3.config.secret_access_key == spec.secret_access_key
      assert s3.config.bucket == nil
    end

    test "raises an error in case s3 file_spec has something nil" do
      name = "file-from-s3.txt"

      spec = %{
        type: :s3,
        bucket_url: nil,
        region: "us-west-1",
        access_key_id: "access-key-1",
        secret_access_key: "secret-access-key-1",
        key: name
      }

      configure_gl_with_reply({:livebook_get_file_entry_spec, name}, {:ok, spec})

      assert_raise ArgumentError, "endpoint is required when bucket is nil", fn ->
        Kino.FS.file_spec(name)
      end

      bucket_url = "https://s3.us-west-1.amazonaws.com/my-bucket"

      spec =
        spec
        |> Map.replace!(:bucket_url, bucket_url)
        |> Map.replace!(:access_key_id, nil)

      configure_gl_with_reply({:livebook_get_file_entry_spec, name}, {:ok, spec})

      assert_raise ArgumentError,
                   "missing :access_key_id for FSS.S3 (set the key or the AWS_ACCESS_KEY_ID env var)",
                   fn ->
                     Kino.FS.file_spec(name)
                   end
    end
  end

  defp configure_gl_with_reply(request, reply) do
    gl =
      spawn(fn ->
        assert_receive {:io_request, from, reply_as, ^request}
        send(from, {:io_reply, reply_as, reply})
      end)

    Process.group_leader(self(), gl)
  end
end
