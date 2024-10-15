defmodule Kino.Shorts do
  @moduledoc """
  Shortcuts for building Kinos.

  This module provides an easy to use Kino API and is meant to
  be imported into your notebooks:

      import Kino.Shorts

  """

  ## Outputs

  @doc """
  Renders a data table output for user-provided tabular data.

  The data must implement the `Table.Reader` protocol. This
  function is a wrapper around `Kino.DataTable.new/1`.

  ## Examples

      import Kino.Shorts

      data = [
        %{id: 1, name: "Elixir", website: "https://elixir-lang.org"},
        %{id: 2, name: "Erlang", website: "https://www.erlang.org"}
      ]

      data_table(data)

  """
  @spec data_table(Table.Reader.t(), keyword()) :: Kino.DataTable.t()
  def data_table(tabular, opts \\ []), do: Kino.DataTable.new(tabular, opts)

  @doc """
  Renders an image of any given format.

  It is a wrapper around `Kino.Image.new/2`.

  ## Examples

      import Kino.Shorts
      content = File.read!("/path/to/image.jpeg")
      image(content, "image/jpeg")

  """
  @spec image(binary(), Kino.Image.common_image_type() | Kino.Image.mime_type()) :: Kino.Image.t()
  def image(content, type), do: Kino.Image.new(content, type)

  @doc """
  Renders an audio of any given format.

  It is a wrapper around `Kino.Audio.new/2`.

  ## Examples

      import Kino.Shorts
      content = File.read!("/path/to/audio.wav")
      audio(content, :wav)

  """
  @spec audio(binary(), Kino.Audio.common_audio_type() | Kino.Audio.mime_type()) :: Kino.Audio.t()
  def audio(content, type), do: Kino.Audio.new(content, type)

  @doc """
  Renders a video of any given format.

  It is a wrapper around `Kino.Video.new/2`.

  ## Examples

      import Kino.Shorts
      content = File.read!("/path/to/video.mp4")
      video(content, :mp4)

  """
  @spec video(binary(), Kino.Video.common_video_type() | Kino.Video.mime_type()) :: Kino.Video.t()
  def video(content, type), do: Kino.Video.new(content, type)

  @doc """
  Renders a file download button.

  The given function is invoked to generate the file content whenever
  a download is requested.

  It is a wrapper around `Kino.Download.new/2`.

  ## Options

    * `:filename` - the default filename suggested for download.
      Defaults to `"download"`

    * `:label` - the button text. Defaults to the value of `:filename`
      if present and `"Download"` otherwise

  ## Examples

      download(fn ->
        "Example text"
      end)

      download(
        fn -> Jason.encode!(%{"foo" => "bar"}) end,
        filename: "data.json"
      )

      download(
        fn -> <<0, 1>> end,
        filename: "data.bin",
        label: "Binary data"
      )

  """
  @spec download((-> binary()), keyword()) :: Kino.Download.t()
  def download(content_fun, opts \\ []), do: Kino.Download.new(content_fun, opts)

  @doc ~S'''
  Renders Markdown content, in case you need richer text.

  It is a wrapper around `Kino.Markdown.new/1`.

  ## Examples

      import Kino.Shorts

      markdown("""
      # Example

      A regular Markdown file.

      ## Code

      ```elixir
      "Elixir" |> String.graphemes() |> Enum.frequencies()
      ```

      ## Table

      | ID | Name   | Website                 |
      | -- | ------ | ----------------------- |
      | 1  | Elixir | https://elixir-lang.org |
      | 2  | Erlang | https://www.erlang.org  |
      """)
  '''
  @spec markdown(String.t()) :: Kino.Markdown.t()
  def markdown(markdown), do: Kino.Markdown.new(markdown)

  @doc """
  Renders plain text content.

  It is similar to `markdown/1`, however doesn't interpret any markup.

  It is a wrapper around `Kino.Text.new/1`.

  ## Examples

      import Kino.Shorts
      text("Hello!")

  """
  @spec text(String.t()) :: Kino.Text.t()
  def text(text), do: Kino.Text.new(text)

  @doc ~S'''
  Renders Mermaid diagrams.

  It is a wrapper around `Kino.Mermaid.new/1`.

  ## Examples

      import Kino.Shorts

      mermaid("""
      graph TD;
        A-->B;
        A-->C;
        B-->D;
        C-->D;
      """)
  '''
  @spec mermaid(String.t(), keyword()) :: Kino.Mermaid.t()
  def mermaid(diagram, opts \\ []), do: Kino.Mermaid.new(diagram, opts)

  @doc """
  A placeholder for static outputs that can be dynamically updated.

  The frame can be updated with the `Kino.Frame` module API.
  Also see `Kino.animate/3`.

  ## Examples

      import Kino.Shorts
      frame = frame() |> Kino.render()

      for i <- 1..100 do
        Kino.Frame.render(frame, i)
        Process.sleep(50)
      end

  """
  @spec frame(keyword()) :: Kino.Frame.t()
  def frame(opts \\ []), do: Kino.Frame.new(opts)

  @doc """
  Displays arbitrarily nested data structure as a tree view.

  It is a wrapper around `Kino.Tree.new/1`.

  ## Examples

      import Kino.Shorts
      tree(Process.info(self()))

  """
  @spec tree(term()) :: Kino.Layout.t()
  def tree(tree), do: Kino.Tree.new(tree)

  @doc ~S'''
  Displays arbitrary static HTML.

  It is a wrapper around `Kino.HTML.new/1`.

  ## Examples

      import Kino.Shorts

      html("""
      <h3>Look!</h3>

      <p>I wrote this HTML from <strong>Kino</strong>!</p>
      """)

  '''
  @spec html(String.t()) :: Kino.HTML.t()
  def html(html), do: Kino.HTML.new(html)

  ## Layout

  @doc """
  Arranges outputs into separate tabs.

  It is a wrapper around `Kino.Layout.tabs/1`.

  ## Examples

      import Kino.Shorts

      data = [
        %{id: 1, name: "Elixir", website: "https://elixir-lang.org"},
        %{id: 2, name: "Erlang", website: "https://www.erlang.org"}
      ]

      tabs([
        Table: data_table(data),
        Raw: data
      ])

  """
  @spec tabs(list({String.t() | atom(), term()})) :: Kino.Layout.t()
  defdelegate tabs(tabs), to: Kino.Layout

  @doc """
  Arranges outputs into a grid.

  Note that the grid does not support scrolling, it always squeezes
  the content, such that it does not exceed the page width.

  It is a wrapper around `Kino.Layout.grid/2`. See the linked function
  for all supported options.

  ## Options

    * `:columns` - the number of columns in the grid. Defaults to `1`

    * `:boxed` - whether the grid should be wrapped in a bordered box.
      Defaults to `false`

    * `:gap` - the amount of spacing between grid items in pixels.
      Defaults to `8`

  ## Examples

      import Kino.Shorts

      images =
        for path <- paths do
          path |> File.read!() |> image(:jpeg)
        end

      grid(images, columns: 3)

  """
  @spec grid(list(term()), keyword()) :: Kino.Layout.t()
  defdelegate grid(terms, opts \\ []), to: Kino.Layout

  ## Inputs

  @doc """
  Renders and reads a new text input.

  ## Options

    * `:default` - the initial input value. Defaults to `""`
  """
  @spec read_text(String.t(), keyword()) :: String.t() | nil
  def read_text(label, opts \\ []) when is_binary(label) and is_list(opts) do
    Kino.Input.text(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new multiline text input.

  ## Options

    * `:default` - the initial input value. Defaults to `""`

    * `:monospace` - whether to use a monospace font inside the textarea.
      Defaults to `false`
  """
  @spec read_textarea(String.t(), keyword()) :: String.t() | nil
  def read_textarea(label, opts \\ []) when is_binary(label) and is_list(opts) do
    Kino.Input.textarea(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new password input.

  ## Options

    * `:default` - the initial input value. Defaults to `""`
  """
  @spec read_password(String.t(), keyword()) :: String.t() | nil
  def read_password(label, opts \\ []) when is_binary(label) and is_list(opts) do
    Kino.Input.password(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new number input.

  ## Options

    * `:default` - the initial input value. Defaults to `nil`
  """
  @spec read_number(String.t(), keyword()) :: number() | nil
  def read_number(label, opts \\ []) when is_binary(label) and is_list(opts) do
    Kino.Input.number(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new URL input.

  ## Options

    * `:default` - the initial input value. Defaults to `nil`
  """
  @spec read_url(String.t(), keyword()) :: String.t() | nil
  def read_url(label, opts \\ []) when is_binary(label) and is_list(opts) do
    Kino.Input.url(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new select input.

  The input expects a list of options in the form `[{value, label}]`,
  where `value` is an arbitrary term and `label` is a descriptive
  string.

  ## Options

    * `:default` - the initial input value. Defaults to the first
      value from the given list of options

  ## Examples

      read_select("Language", [en: "English", fr: "Français"])

      read_select("Language", [{1, "One"}, {2, "Two"}, {3, "Three"}])
  """
  @spec read_select(String.t(), list({value :: term(), label :: String.t()}), keyword()) ::
          String.t()
  def read_select(label, options, opts \\ [])
      when is_binary(label) and is_list(options) and is_list(opts) do
    Kino.Input.select(label, options, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new checkbox.

  ## Options

    * `:default` - the initial input value. Defaults to `false`
  """
  @spec read_checkbox(String.t(), keyword()) :: boolean()
  def read_checkbox(label, opts \\ []) when is_binary(label) and is_list(opts) do
    Kino.Input.checkbox(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new slider input.

  ## Options

    * `:default` - the initial input value. Defaults to the
      minimum value

    * `:min` - the minimum value

    * `:max` - the maximum value

    * `:step` - the slider increment
  """
  @spec read_range(String.t(), keyword()) :: float()
  def read_range(label, opts \\ []) when is_binary(label) and is_list(opts) do
    Kino.Input.range(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new datetime input.

  ## Options

    * `:default` - the initial input value. Defaults to `nil`

    * `:min` - the minimum datetime value (in UTC)

    * `:max` - the maximum datetime value (in UTC)
  """
  @spec read_utc_datetime(String.t(), keyword()) :: NaiveDateTime.t() | nil
  def read_utc_datetime(label, opts \\ []) when is_binary(label) and is_list(opts) do
    Kino.Input.utc_datetime(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new time input.

  ## Options

    * `:default` - the initial input value. Defaults to `nil`

    * `:min` - the minimum time value (in UTC)

    * `:max` - the maximum time value (in UTC)
  """
  @spec read_utc_time(String.t(), keyword()) :: Time.t() | nil
  def read_utc_time(label, opts \\ []) when is_binary(label) and is_list(opts) do
    Kino.Input.utc_time(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new date input.

  ## Options

    * `:default` - the initial input value. Defaults to `nil`

    * `:min` - the minimum date value

    * `:max` - the maximum date value
  """
  @spec read_date(String.t(), keyword()) :: Date.t() | nil
  def read_date(label, opts \\ []) when is_binary(label) and is_list(opts) do
    Kino.Input.date(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new color input.

  ## Options

    * `:default` - the initial input value. Defaults to `#6583FF`
  """
  @spec read_color(String.t(), keyword()) :: String.t() | nil
  def read_color(label, opts \\ []) when is_binary(label) and is_list(opts) do
    Kino.Input.color(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new image input.

  See `Kino.Input.image/2` for all supported formats and options.

  > #### Warning {: .warning}
  >
  > The image input is shared by default: once you upload an image,
  > the image will be replicated to all users reading the notebook.
  > Use `Kino.Control.form/2` if you want each user to have a distinct
  > image upload with an explicit submission button.
  """
  @spec read_image(String.t(), keyword()) ::
          %{
            file_ref: term(),
            height: pos_integer(),
            width: pos_integer(),
            format: :rgb | :png | :jpeg
          }
          | nil
  def read_image(label, opts \\ []) do
    Kino.Input.image(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new audio input.

  See `Kino.Input.audio/2` for all supported formats and options.

  > #### Warning {: .warning}
  >
  > The audio input is shared by default: once you upload an audio,
  > the audio will be replicated to all users reading the notebook.
  > Use `Kino.Control.form/2` if you want each user to have a distinct
  > audio upload with an explicit submission button.
  """
  @spec read_audio(String.t(), keyword()) ::
          %{
            file_ref: term(),
            num_channels: pos_integer(),
            sampling_rate: pos_integer(),
            format: :pcm_f32 | :wav
          }
          | nil
  def read_audio(label, opts \\ []) do
    Kino.Input.audio(label, opts) |> Kino.render() |> Kino.Input.read()
  end

  @doc """
  Renders and reads a new file input.

  The file path can then be accessed using `Kino.Input.file_path/1`.
  See `Kino.Input.file/2` for additional considerations.

  > #### Warning {: .warning}
  >
  > The file input is shared by default: once you upload a file,
  > the file will be replicated to all users reading the notebook.
  > Use `Kino.Control.form/2` if you want each user to have a distinct
  > file upload with an explicit submission button.

  ## Options

    * `:accept` - the list of accepted file types (either extensions
      or MIME types) or `:any`. Defaults to `:any`

  """
  @spec read_file(String.t(), keyword()) ::
          %{
            file_ref: String.t(),
            client_name: String.t()
          }
          | nil
  def read_file(label, opts \\ []) when is_binary(label) and is_list(opts) do
    Kino.Input.file(label, opts) |> Kino.render() |> Kino.Input.read()
  end
end
