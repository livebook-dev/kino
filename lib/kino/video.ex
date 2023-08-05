defmodule Kino.Video do
  @moduledoc """
  A kino for rendering a binary video.

  ## Examples

      content = File.read!("/path/to/video.mp4")
      Kino.Video.new(content, :mp4)
  """

  use Kino.JS

  @type t :: Kino.JS.t()

  @type mime_type :: binary()
  @type common_video_type :: :mp4 | :ogg | :avi | :mwv | :mov
  @doc """
  Creates a new kino displaying the given binary video.

  The given type be either `:mp4`, `:ogg`, `:avi`, `:wmv`, `:mov`
  or a string with video MIME type.

  """
  @spec new(binary(), common_video_type() | mime_type()) :: t()
  def new(content, type) when is_binary(content) do
    Kino.JS.new(__MODULE__, data_url(content, type))
  end

  defp data_url(content, type) do
    base64 = Base.encode64(content)
    "data:#{mime_type!(type)};base64,#{base64}"
  end

  defp mime_type!(:mp4), do: "video/mp4"
  defp mime_type!(:ogg), do: "video/ogg"
  defp mime_type!(:avi), do: "video/x-msvideo"
  defp mime_type!(:wmv), do: "video/x-ms-wmv"
  defp mime_type!(:mov), do: "video/quicktime"
  defp mime_type!("video/" <> _ = mime_type), do: mime_type

  defp mime_type!(other) do
    raise ArgumentError,
          "expected video type to be either :mp4, :ogg, :avi, :wmv, :mov, or an video MIME type string, got: #{inspect(other)}"
  end

  asset "main.js" do
    """
    export function init(ctx, data) {
      ctx.root.innerHTML = `
        <div class="root">
            <video controls src="${data}" />
        </div>
      `;

    }
    """
  end
end
