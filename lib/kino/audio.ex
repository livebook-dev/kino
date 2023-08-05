defmodule Kino.Audio do
  @moduledoc """
  A kino for rendering a binary audio.

  ## Examples

      content = File.read!("/path/to/audio.wav")
      Kino.Audio.new(content, :wav)
  """

  use Kino.JS

  @type t :: Kino.JS.t()

  @type mime_type :: binary()
  @type common_audio_type :: :wav | :mp3 | :mpeg | :ogg
  @doc """
  Creates a new kino displaying the given binary audio.

  The given type be either `:wav`, `:mp3`/`:mpeg`, `:ogg`
  or a string with audio MIME type.

  """
  @spec new(binary(), common_audio_type() | mime_type()) :: t()
  def new(content, type) when is_binary(content) do
    Kino.JS.new(__MODULE__, data_url(content, type))
  end

  defp data_url(content, type) do
    base64 = Base.encode64(content)
    "data:#{mime_type!(type)};base64,#{base64}"
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

  asset "main.js" do
    """
    export function init(ctx, data) {
      ctx.root.innerHTML = `
        <div class="root">
            <audio controls src="${data}" />
        </div>
      `;

    }
    """
  end
end
