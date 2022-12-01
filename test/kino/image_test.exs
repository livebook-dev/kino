defmodule Kino.ImageTest do
  use ExUnit.Case, async: true

  describe "new/2" do
    test "raises an error for a non-image MIME type" do
      assert_raise ArgumentError,
                   ~s{expected image type to be either :jpeg, :png, :gif, :svg, :pixel or an image MIME type string, got: "application/json"},
                   fn ->
                     Kino.Image.new(<<>>, "application/json")
                   end
    end

    test "raises an error for an invalid type shorthand" do
      assert_raise ArgumentError,
                   "expected image type to be either :jpeg, :png, :gif, :svg, :pixel or an image MIME type string, got: :invalid",
                   fn ->
                     Kino.Image.new(<<>>, :invalid)
                   end
    end

    test "converts a valid type shorthand into MIME type" do
      assert %{mime_type: "image/jpeg"} = Kino.Image.new(<<>>, :jpeg)
    end
  end

  describe "new/1" do
    test "raises an error for non :u8 tensor" do
      assert_raise ArgumentError,
                   "expected Nx.Tensor to have type {:u, 8}, got: {:f, 32}",
                   fn ->
                     tensor = Nx.broadcast(Nx.tensor(0, type: :f32), {10, 10, 3})
                     Kino.Image.new(tensor)
                   end
    end

    test "raises an error for an invalid shape" do
      assert_raise ArgumentError,
                   "expected Nx.Tensor to have shape {height, width, channels}, got: {1, 10, 10, 3}",
                   fn ->
                     tensor = Nx.broadcast(Nx.tensor(0, type: :u8), {1, 10, 10, 3})
                     Kino.Image.new(tensor)
                   end

      assert_raise ArgumentError,
                   "expected Nx.Tensor to have shape {height, width, channels}, got: {10, 10, 5}",
                   fn ->
                     tensor = Nx.broadcast(Nx.tensor(0, type: :u8), {10, 10, 5})
                     Kino.Image.new(tensor)
                   end
    end

    test "converts a compatible tensor to image" do
      tensor = Nx.broadcast(Nx.tensor(0, type: :u8), {10, 10, 3})
      assert %{mime_type: "image/x-pixel"} = Kino.Image.new(tensor)
    end
  end
end
