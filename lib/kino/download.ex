defmodule Kino.Download do
  @moduledoc false

  use Kino.JS
  use Kino.JS.Live

  @doc """
  Renders a download button.  The content of downloaded file is
  prepared on the server by invoking the `content_fun` argument only
  when the button is clicked.

  ## Examples

      Kino.Download.new("file.json", fn ->
        ~s/{"foo": "bar"}/
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
    {:ok, %{filename: ctx.assigns.filename}, ctx}
  end

  @impl true
  def handle_event("download", %{}, ctx) do
    file_content = ctx.assigns.content_fun.()

    reply_payload = {:binary, %{}, file_content}

    broadcast_event(ctx, "download_content", reply_payload)

    {:noreply, ctx}
  end

  asset "main.js" do
    """
    export function init(ctx, data) {

      // Handle the event which initiates the actual downloading of the file
      ctx.handleEvent("download_content", ([info, arrayBuffer]) => {
        const content = bufferToBase64(arrayBuffer);

        const a = document.createElement('a');
        a.href = `data:application/octet-stream;base64,${content}`;
        a.download = data.filename;
        a.click();
      });

      // Create the Download button
      const button = document.createElement('button');
      button.innerHTML = `Download ${data.filename}`;
      button.addEventListener('click', buttonClicked);
      ctx.root.appendChild(button);

      function buttonClicked() {
        ctx.pushEvent("download", {})
      }
    }

    function bufferToBase64(buffer) {
      let binaryString = "";
      const bytes = new Uint8Array(buffer);
      const length = bytes.byteLength;

      for (let i = 0; i < length; i++) {
        binaryString += String.fromCharCode(bytes[i]);
      }

      return btoa(binaryString);
    }
    """
  end
end
