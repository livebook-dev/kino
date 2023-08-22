defmodule Kino.FSTest do
  use ExUnit.Case, async: true

  describe "file_spec_to_fss/1" do
    test "returns a file spec" do
      path = "/home/bob/file.txt"
      assert %FSS.Local.Entry{path: ^path} = Kino.FS.file_spec_to_fss(%{type: :local, path: path})
    end

    test "returns an HTTP FSS entry" do
      url = "https://example.com/file.txt"

      assert %FSS.HTTP.Entry{url: ^url, config: %FSS.HTTP.Config{headers: []}} =
               Kino.FS.file_spec_to_fss(%{type: :url, url: url})
    end

    test "returns a S3 FSS entry" do
      bucket_url = "https://s3.us-west-1.amazonaws.com/my-bucket"

      s3_spec = %{
        type: :s3,
        bucket_url: bucket_url,
        region: "us-west-1",
        access_key_id: "access-key-1",
        secret_access_key: "secret-access-key-1",
        key: "file"
      }

      assert %FSS.S3.Entry{} = s3 = Kino.FS.file_spec_to_fss(s3_spec)

      assert s3.key == s3_spec.key

      assert s3.config.region == s3_spec.region
      assert s3.config.endpoint == bucket_url
      assert s3.config.access_key_id == s3_spec.access_key_id
      assert s3.config.secret_access_key == s3_spec.secret_access_key
      assert s3.config.bucket == nil
    end

    test "raises an error in case s3 file_spec has something nil" do
      s3_spec = %{
        type: :s3,
        bucket_url: nil,
        region: "us-west-1",
        access_key_id: "access-key-1",
        secret_access_key: "secret-access-key-1",
        key: "file"
      }

      assert_raise ArgumentError, "endpoint is required when bucket is nil", fn ->
        Kino.FS.file_spec_to_fss(s3_spec)
      end

      bucket_url = "https://s3.us-west-1.amazonaws.com/my-bucket"

      s3_spec =
        s3_spec
        |> Map.replace!(:bucket_url, bucket_url)
        |> Map.replace!(:access_key_id, nil)

      assert_raise ArgumentError,
                   "missing :access_key_id for FSS.S3 (set the key or the AWS_ACCESS_KEY_ID env var)",
                   fn ->
                     Kino.FS.file_spec_to_fss(s3_spec)
                   end
    end
  end
end
