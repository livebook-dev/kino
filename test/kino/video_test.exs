defmodule Kino.VideoTest do
  use Kino.LivebookCase, async: true

  describe "new/2" do
    test "raises an error for a non-image MIME type" do
      assert_raise ArgumentError,
                   ~s{expected video type to be either :mp4, :ogg, :avi, :wmv, :mov, or a video MIME type string, got: "application/json"},
                   fn ->
                     Kino.Video.new(<<>>, "application/json")
                   end
    end

    test "raises an error for an invalid type shorthand" do
      assert_raise ArgumentError,
                   "expected video type to be either :mp4, :ogg, :avi, :wmv, :mov, or a video MIME type string, got: :invalid",
                   fn ->
                     Kino.Video.new(<<>>, :invalid)
                   end
    end

    test "mime type shorthand and default opts" do
      kino = Kino.Video.new(<<>>, :mp4)
      assert {:binary, %{type: "video/mp4", opts: "controls"}, <<>>} == connect(kino)
    end

    test "custom mime type and custom opts" do
      kino = Kino.Video.new(<<>>, "video/h123", loop: true)
      assert {:binary, %{type: "video/h123", opts: "controls loop"}, <<>>} == connect(kino)
    end
  end
end
