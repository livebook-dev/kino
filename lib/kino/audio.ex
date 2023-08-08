defmodule Kino.Audio do
  @moduledoc """
  A kino for rendering a binary audio.

  ## Examples

      content = File.read!("/path/to/audio.wav")
      Kino.Audio.new(content, :wav)

      content = File.read!("/path/to/audio.wav")
      Kino.Audio.new(content, :wav, autoplay: true, loop: true)
  """

  use Kino.JS, assets_path: "lib/assets/audio"
  use Kino.JS.Live

  @type t :: Kino.JS.Live.t()

  @type mime_type :: binary()
  @type common_audio_type :: :wav | :mp3 | :mpeg | :ogg

  @doc """
  Creates a new kino displaying the given binary audio.

  The given type be either `:wav`, `:mp3`/`:mpeg`, `:ogg`
  or a string with audio MIME type.

  ## Options

    * `:autoplay` - whether the audio should start playing as soon as
      it is rendered. Defaults to `false`

    * `:loop` - whether the audio should loop. Defaults to `false`

    * `:muted` - whether the audio should be muted. Defaults to `false`

  """
  @spec new(binary(), common_audio_type() | mime_type(), keyword()) :: t()
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

  defp mime_type!(:wav), do: "audio/wav"
  defp mime_type!(:mp3), do: "audio/mpeg"
  defp mime_type!(:mpeg), do: "audio/mpeg"
  defp mime_type!(:ogg), do: "audio/ogg"
  defp mime_type!("audio/" <> _ = mime_type), do: mime_type

  defp mime_type!(other) do
    raise ArgumentError,
          "expected audio type to be either :wav, :mp3, :mpeg, :ogg, or an audio MIME type string, got: #{inspect(other)}"
  end
end
