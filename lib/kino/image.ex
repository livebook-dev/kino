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
  @type common_image_type :: :jpeg | :png | :gif | :svg

  @doc """
  Creates a new kino displaying the given binary image.

  The given type be either `:jpeg`, `:png`, `:gif`, `:svg`
  or a string with image MIME type.
  """
  @spec new(binary(), common_image_type() | mime_type()) :: t()
  def new(content, type) do
    %__MODULE__{content: content, mime_type: mime_type!(type)}
  end

  defp mime_type!(:jpeg), do: "image/jpeg"
  defp mime_type!(:png), do: "image/png"
  defp mime_type!(:gif), do: "image/gif"
  defp mime_type!(:svg), do: "image/svg+xml"
  defp mime_type!("image/" <> _ = mime_type), do: mime_type

  defp mime_type!(other) do
    raise ArgumentError,
          "expected image type to be either :jpeg, :png, :gif, :svg or an image MIME type string, got: #{inspect(other)}"
  end
end
