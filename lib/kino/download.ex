defmodule Kino.Download do
  @moduledoc """
  A kino for downloading file content.

  ## Examples

      Kino.Download.new(fn ->
        "Example text"
      end)

      Kino.Download.new(
        fn -> Jason.encode!(%{"foo" => "bar"}) end,
        filename: "data.json"
      )

      Kino.Download.new(
        fn -> <<0, 1>> end,
        filename: "data.bin"
      )

  """

  use Kino.JS, assets_path: "lib/assets/download"
  use Kino.JS.Live

  @type t :: Kino.JS.Live.t()

  @doc """
  Creates a button for file download.

  The given function is invoked to generate the file content whenever
  a download is requested.

  ## Options

    * `:filename` - the default filename suggested for download

  """
  @spec new((() -> binary()), keyword()) :: t()
  def new(content_fun, opts \\ []) do
    opts = Keyword.validate!(opts, [:filename])
    filename = opts[:filename]
    Kino.JS.Live.new(__MODULE__, {content_fun, filename})
  end

  @impl true
  def init({content_fun, filename}, ctx) do
    {:ok, assign(ctx, content_fun: content_fun, filename: filename)}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, %{filename: ctx.assigns.filename}, ctx}
  end

  @impl true
  def handle_event("download", %{}, ctx) do
    file_content = ctx.assigns.content_fun.()
    reply_payload = {:binary, %{}, file_content}
    send_event(ctx, ctx.origin, "download_content", reply_payload)
    {:noreply, ctx}
  end
end
