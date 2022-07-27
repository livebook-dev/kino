defmodule Kino.Download do
  @moduledoc false

  use Kino.JS
  use Kino.JS.Live

  @doc """
  Initiates a download.  The content is generated lazily by invoking
  the `content_fun` argument on the server when the "Download" button
  is clicked.

  ## Examples

  Passing the content from an existing variable:

      json = ~s/{"foo": "bar"}/
      Kino.Download.new("file.json", fn -> json end)

  Lazily generating a large file:

      Kino.Download.new("large-file.txt", fn ->
        String.duplicate("data ", 10_000_000)
      end)
  """
  def new(filename, content_fun) do
    Kino.JS.Live.new(__MODULE__, {filename, content_fun})
  end

  @impl true
  def init({filename, content_fun}, ctx) do
    {:ok, assign(ctx, filename: filename, content_fun: content_fun)}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, Map.take(ctx.assigns, [:filename]), ctx}
  end

  @impl true
  def handle_event("prepare_download", %{"filename" => filename}, ctx) do
    ctx = assign(ctx, filename: filename)

    # To keep things generic the content is a base64-encoded binary
    file_content =
      ctx.assigns.content_fun.()
      |> Base.encode64()

    reply_payload = {:binary, %{filename: ctx.assigns.filename}, file_content}

    broadcast_event(ctx, "do_download", reply_payload)

    {:noreply, ctx}
  end

  asset "main.js" do
    """
    export function init(ctx, data) {

      // Handle the event which initiates the actual downloading of the file
      ctx.handleEvent("do_download", ([info, arrayBuffer]) => {
        const decoder = new TextDecoder("utf-8");
        const content = decoder.decode(arrayBuffer);

        // Create a hidden element that we can attach the download to
        const hiddenElement = document.createElement('a');
        hiddenElement.href = `data:attachment/application/octet-stream;base64,${content}`;
        hiddenElement.target = '_blank';
        hiddenElement.download = info.filename;
        hiddenElement.click();
      });

      // Create the Download button
      const button = document.createElement('button');
      button.innerHTML = `Download ${data.filename}`;
      button.addEventListener('click', buttonClicked);
      ctx.root.appendChild(button);

      function buttonClicked() {
        ctx.pushEvent("prepare_download", {filename: data.filename})
      }
    }
    """
  end
end
