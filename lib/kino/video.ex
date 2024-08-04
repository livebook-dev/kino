defmodule Kino.Video do
  @moduledoc """
  A kino for rendering a binary video.

  ## Examples

      content = File.read!("/path/to/video.mp4")
      Kino.Video.new(content, :mp4)

      content = File.read!("/path/to/video.mp4")
      Kino.Video.new(content, :mp4, autoplay: true, loop: true)

  """

  use Kino.JS, assets_path: "lib/assets/video"
  use Kino.JS.Live

  @type t :: Kino.JS.Live.t()

  @type mime_type :: binary()
  @type common_video_type :: :mp4 | :ogg | :avi | :mwv | :mov

  @doc """
  Creates a new kino displaying the given binary video.

  The given type can be either `:mp4`, `:ogg`, `:avi`, `:wmv`, `:mov`
  or a string with video MIME type.

  ## Options

    * `:autoplay` - whether the video should start playing as soon as
      it is rendered. Defaults to `false`

    * `:loop` - whether the video should loop. Defaults to `false`

    * `:muted` - whether the video should be muted. Defaults to `false`

  """
  @spec new(binary(), common_video_type() | mime_type(), list()) :: t()
  def new(content, type, opts \\ []) when is_binary(content) do
    opts =
      Keyword.validate!(opts,
        autoplay: false,
        loop: false,
        muted: false
      )

    Kino.JS.Live.new(__MODULE__, %{
      content: content,
      type: mime_type!(type),
      opts:
        Enum.reduce(opts, "controls", fn {opt, val}, acc ->
          if val do
            "#{acc} #{opt}"
          else
            acc
          end
        end)
    })
  end

  @impl true
  def init(assigns, ctx) do
    {:ok, assign(ctx, assigns)}
  end

  @impl true
  def handle_connect(%{assigns: %{content: content, type: type, opts: opts}} = ctx) do
    payload = {:binary, %{type: type, opts: opts}, content}
    {:ok, payload, ctx}
  end

  defp mime_type!(:mp4), do: "video/mp4"
  defp mime_type!(:ogg), do: "video/ogg"
  defp mime_type!(:avi), do: "video/x-msvideo"
  defp mime_type!(:wmv), do: "video/x-ms-wmv"
  defp mime_type!(:mov), do: "video/quicktime"
  defp mime_type!("video/" <> _ = mime_type), do: mime_type

  defp mime_type!(other) do
    raise ArgumentError,
          "expected video type to be either :mp4, :ogg, :avi, :wmv, :mov, or a video MIME type string, got: #{inspect(other)}"
  end
end
