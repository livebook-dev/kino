defmodule Kino.AudioTest do
  use ExUnit.Case, async: true

  describe "new/2" do
    test "raises an error for a non-image MIME type" do
      assert_raise ArgumentError,
                   ~s{expected audio type to be either :wav, :mp3, :mpeg, :ogg, or an audio MIME type string, got: "application/json"},
                   fn ->
                     Kino.Audio.new(<<>>, "application/json")
                   end
    end

    test "raises an error for an invalid type shorthand" do
      assert_raise ArgumentError,
                   "expected audio type to be either :wav, :mp3, :mpeg, :ogg, or an audio MIME type string, got: :invalid",
                   fn ->
                     Kino.Audio.new(<<>>, :invalid)
                   end
    end

    # test "converts a valid type shorthand into MIME type" do
    #   assert %{mime_type: "image/wav"} = Kino.Audio.new(<<>>, :wav)
    # end
  end
end
