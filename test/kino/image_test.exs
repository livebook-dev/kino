defmodule Kino.ImageTest do
  use ExUnit.Case, async: true

  describe "new/2" do
    test "raises an error for a non-image MIME type" do
      assert_raise ArgumentError,
                   "expected image type to be either :jpeg, :png, :gif, :svg or an image MIME type string, got: \"application/json\"",
                   fn ->
                     Kino.Image.new(<<>>, "application/json")
                   end
    end

    test "raises an error for an invalid type shorthand" do
      assert_raise ArgumentError,
                   "expected image type to be either :jpeg, :png, :gif, :svg or an image MIME type string, got: :invalid",
                   fn ->
                     Kino.Image.new(<<>>, :invalid)
                   end
    end

    test "converts a valid type shorthand into MIME type" do
      assert %{mime_type: "image/jpeg"} = Kino.Image.new(<<>>, :jpeg)
    end
  end
end
