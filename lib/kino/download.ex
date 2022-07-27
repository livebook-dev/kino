defmodule Kino.Download do
  @moduledoc ~S'''
  Built on top of `Kino.JS`, uses Javascript to initiate a download
  on the client's machine.
  '''
  use Kino.JS

  @doc ~S'''
  Initiates a download on the client's machine.  The content is
  generated lazily by invoking the `content_fun` argument.

  ## Examples

  Passing the content from an existing variable:

      json = ~s/{"foo": "bar"}/
      Kino.Download.start("file.json", fn -> json end)

  Lazily generating a large file:

      Kino.Download.start("large-file.txt", fn ->
        String.duplicate("data ", 10_000_000)
      end)
  '''
  @spec start(String.t(), (() -> String.t())) :: Kino.JS.t()
  def start(filename, content_fun) do
    data = %{
      content: content_fun.(),
      filename: filename
    }

    Kino.JS.new(__MODULE__, data)
  end

  asset "main.js" do
    """
    export function init(ctx, data) {
      var hiddenElement = document.createElement('a');
      hiddenElement.href = 'data:attachment/text,' + encodeURI(data.content);
      hiddenElement.target = '_blank';
      hiddenElement.download = data.filename;
      hiddenElement.click();
    }
    """
  end
end
