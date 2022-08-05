defmodule Kino.DownloadTest do
  use Kino.LivebookCase, async: true

  test "sends generated file content to the client who triggered the download" do
    kino = Kino.Download.new(fn -> "text" end)
    _ = connect(kino)

    push_event(kino, "download", %{})
    assert_send_event(kino, "download_content", {:binary, %{}, "text"})
  end
end
