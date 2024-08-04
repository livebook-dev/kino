defmodule Kino.Image do
  @moduledoc """
  A kino for rendering a binary image.

  This is just a meta-struct that implements the `Kino.Render`
  protocol, so that it gets rendered as the underlying image.

  ## Examples

      content = File.read!("/path/to/image.jpeg")
      Kino.Image.new(content, "image/jpeg")
  """

  @enforce_keys [:content, :mime_type]

  defstruct [:content, :mime_type]

  @opaque t :: %__MODULE__{
            content: binary(),
            mime_type: mime_type()
          }

  @type mime_type :: binary()
  @type common_image_type :: :jpeg | :jpg | :png | :gif | :svg | :pixel

  @doc """
  Creates a new kino displaying the given binary image.

  The given type can be either `:jpeg`/`:jpg`, `:png`, `:gif`, `:svg`, `:pixel`
  or a string with image MIME type.

  ## Pixel data

  Note that a special `image/x-pixel` MIME type is supported. The
  binary consists of the following consecutive parts:

    * height - 32 bits (unsigned big-endian integer)
    * width - 32 bits (unsigned big-endian integer)
    * channels - 8 bits (unsigned integer)
    * data - pixel data in HWC order

  Pixel data consists of 8-bit unsigned integers. The number of channels
  can be either: 1 (grayscale), 2 (grayscale + alpha), 3 (RGB), or 4
  (RGB + alpha).
  """
  @spec new(binary(), common_image_type() | mime_type()) :: t()
  def new(content, type) when is_binary(content) do
    %__MODULE__{content: content, mime_type: mime_type!(type)}
  end

  defp mime_type!(:jpeg), do: "image/jpeg"
  defp mime_type!(:jpg), do: "image/jpeg"
  defp mime_type!(:png), do: "image/png"
  defp mime_type!(:gif), do: "image/gif"
  defp mime_type!(:svg), do: "image/svg+xml"
  defp mime_type!(:pixel), do: "image/x-pixel"
  defp mime_type!("image/" <> _ = mime_type), do: mime_type

  defp mime_type!(other) do
    raise ArgumentError,
          "expected image type to be either :jpeg, :png, :gif, :svg, :pixel or an image MIME type string, got: #{inspect(other)}"
  end

  @compile {:no_warn_undefined, Nx}

  @doc """
  Creates a new kino similarly to `new/2` from a compatible term.

  Currently the supported terms are:

    * `Nx.Tensor` in HWC order

  """
  @spec new(struct()) :: t()
  def new(tensor) when is_struct(tensor, Nx.Tensor) do
    type = Nx.type(tensor)

    unless type == {:u, 8} do
      raise ArgumentError, "expected Nx.Tensor to have type {:u, 8}, got: #{inspect(type)}"
    end

    {height, width, channels} =
      case Nx.shape(tensor) do
        shape = {_height, _width, channels} when channels in 1..4 ->
          shape

        shape ->
          raise ArgumentError,
                "expected Nx.Tensor to have shape {height, width, channels}, got: #{inspect(shape)}"
      end

    data = Nx.to_binary(tensor)
    content = <<height::32-big, width::32-big, channels::8, data::binary>>
    new(content, :pixel)
  end
end
