defmodule Kino.JS do
  @moduledoc ~S'''
  Allows for defining custom JavaScript powered kinos.

  ## Example

  Here's how we could define a minimal kino that embeds the given
  HTML directly into the page.

      defmodule KinoDocs.HTML do
        use Kino.JS

        def new(html) do
          Kino.JS.new(__MODULE__, html)
        end

        asset "main.js" do
          """
          export function init(ctx, html) {
            ctx.root.innerHTML = html;
          }
          """
        end
      end

  Let's break down the API.

  To define a custom kino we need to create a new module. In this
  case we go with `KinoDocs.HTML`.

  We start by adding `use Kino.JS`, which makes our module
  asset-aware. In particular, it allows us to use the `asset/2`
  macro to define arbitrary files directly in the module source.

  All kinos require a `main.js` file that  defines a JavaScript
  module and  becomes the entrypoint on the client side. The
  JavaScript module is expected to export the `init(ctx, data)`
  function, where `ctx` is a special object (discussed in
  detail later) and `data` is the kino data passed from the
  Elixir side. In our example the `init` function accesses the
  root element with `ctx.root` and overrides its content with
  the given HTML string.

  Finally, we define the `new(html)` function that creates kinos
  with the given HTML. Underneath we call `Kino.JS.new/2`
  specifying our module as the kino type and passing the data
  (available in the JavaScript `init` function later). Again,
  it's a convention for each kino module to define a `new`
  function to provide uniform experience for the end user.

  ## Assets

  We already saw how to define a JavaScript (or any other) file
  using the `asset/2` macro, however in most cases it's preferable
  to put assets in a dedicated directory to benefit from syntax
  highlighting and other editor features. To do that, we just need
  to specify where the corresponding directory is located:

      use Kino.JS, assets_path: "lib/assets/html"

  ### Stylesheets

  The `ctx.importCSS(url)` function allows us to load CSS from the given
  URL into the page. The stylesheet can be an external resource, such as
  a font from Google Fonts or a custom asset (as outlined above). Here's
  an example of both:

      defmodule KinoDocs.HTML do
        use Kino.JS

        def new(html) do
          Kino.JS.new(__MODULE__, html)
        end

        asset "main.js" do
          """
          export function init(ctx, html) {
            ctx.importCSS("https://fonts.googleapis.com/css?family=Sofia")
            ctx.importCSS("main.css")

            ctx.root.innerHTML = html;
          }
          """
        end

        asset "main.css" do
          """
          body {
            font-family: "Sofia", sans-serif;
          }
          """
        end
      end

  ### URLs

  When using multiple asset files, make sure to use relative URLs.
  For example, when adding an image to the page, instead of:

      <img src="/images/cat.jpeg" />

  Do:

      <img src="./images/cat.jpeg" />

  This will correctly point to the `images/cat.jpeg` file in your
  assets.

  ### Security

  Note that all assets are assumed public and Livebook doesn't
  enforce authentication when loading them. Therefore, never
  include any sensitive credentials in the assets source, instead
  pass them as arguments from your Elixir code.

  ## JavaScript API

  In the example we briefly introduced the `ctx` (context) object
  that is made available in the `init(ctx, data)` function. This
  object encapsulates all of the Livebook-specific API that we can
  call on the JavaScript side.

  ### Properties

    * `ctx.root` - the root element controlled by the kino

  ### Functions

    * `ctx.importCSS(url)` - loads CSS from the given URL into the
      page. Returns a `Promise` that resolves once the CSS is loaded

    * `ctx.importJS(url)` - loads JS from the given URL into the page
      using a regular `<script>` tag. Returns a `Promise` that resolves
      once the JS is loaded

    * `ctx.handleEvent(event, callback)` - registers an event
      handler. Once `event` is broadcasted, `callback` is executed
      with the event payload. This applies to `Kino.JS.Live` kinos

    * `ctx.pushEvent(event, payload)` - sends an event to the kino
      server, where it is handled with `c:Kino.JS.Live.handle_event/3`.
      This applies to `Kino.JS.Live` kinos

    * `ctx.handleSync(callback)` - registers a synchronization handler,
      it should flush any deferred UI changes to the server. This
      applies to `Kino.SmartCell` cells

    * `ctx.selectSecret(callback, preselectName)` - asks the user to
      select a Livebook secret. Suggests `preselectName` as the default
      choice. When the user selects a secret, `callback` is called
      with the secret name

  ## CDN

  It is possible to use a regular JavaScript bundler for generating
  the assets, however in many cases a simpler and preferred approach
  is to import the necessary dependencies directly from a CDN.

  To give a concrete example, here's how we could use the `mermaid`
  JavaScript package for rendering diagrams:

      defmodule KinoDocs.Mermaid do
        use Kino.JS

        def new(graph) do
          Kino.JS.new(__MODULE__, graph)
        end

        asset "main.js" do
          """
          import "https://cdn.jsdelivr.net/npm/mermaid@9.1.3/dist/mermaid.min.js";

          mermaid.initialize({ startOnLoad: false });

          export function init(ctx, graph) {
            mermaid.render("graph1", graph, (svgSource, bindListeners) => {
              ctx.root.innerHTML = svgSource;
              bindListeners && bindListeners(ctx.root);
            });
          }
          """
        end
      end

  And we would use it like so:

      KinoDocs.Mermaid.new("""
      graph TD;
        A-->B;
        A-->C;
        B-->D;
        C-->D;
      """)

  ## Live kinos

  So far we covered the API for defining static kinos, where the
  JavaScript side only receives the initial data and there is no
  further interaction with the Elixir side. To introduce such
  interaction, see `Kino.JS.Live` as a next step in our discussion.
  '''

  defstruct [:module, :ref, :export]

  @opaque t :: %__MODULE__{module: module(), ref: Kino.Output.ref(), export: map()}

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      import Kino.JS, only: [asset: 2]

      @before_compile Kino.JS

      @js_opts opts

      Module.register_attribute(__MODULE__, :inline_assets, accumulate: true)
    end
  end

  @doc ~S'''
  Defines an asset file.

  This serves as a convenience when prototyping or building simple
  kinos, otherwise you most likely want to put assets in separate
  files. See the [Assets](#module-assets) for more details.

  ## Examples

      asset "main.js" do
        """
        export function init(ctx, data) {
          ...
        }
        """
      end

      asset "main.css" do
        """
        .box {
          ...
        }
        """
      end
  '''
  defmacro asset(name, do: block) do
    quote bind_quoted: [name: name, content: block] do
      Module.put_attribute(__MODULE__, :inline_assets, {name, content})
    end
  end

  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :js_opts)
    assets_path = opts[:assets_path]
    asset_paths = __paths__(assets_path)

    loaded_assets =
      for path <- asset_paths do
        abs_path = Path.join(assets_path, path)
        Module.put_attribute(env.module, :external_resource, Path.relative_to_cwd(abs_path))
        content = File.read!(abs_path)
        {path, content}
      end

    inline_assets = Module.get_attribute(env.module, :inline_assets)

    any_inline_assets? = inline_assets != []
    assets_path_defined? = assets_path != nil

    assets =
      case {any_inline_assets?, assets_path_defined?} do
        {true, false} ->
          inline_assets

        {false, true} ->
          if loaded_assets == [] do
            IO.warn(
              "assets directory specified for #{inspect(env.module)}, but no files" <>
                " found in #{inspect(assets_path)}",
              Macro.Env.stacktrace(env)
            )
          end

          loaded_assets

        {true, true} ->
          IO.warn(
            "ignoring files in #{inspect(assets_path)} because #{inspect(env.module)}" <>
              " already defines inline assets with the assets/2 macro",
            Macro.Env.stacktrace(env)
          )

          inline_assets

        {false, false} ->
          message = ~s'''
          no assets defined for #{inspect(env.module)}.

          Make sure to either explicitly specify assets directory:

              use Kino.JS, assets_path: "lib/assets/my_kino"

          Or define assets inline:

              asset "main.js" do
                """
                export function init(ctx, data) {
                  ...
                }
                """
              end
          '''

          IO.warn(message, Macro.Env.stacktrace(env))

          []
      end

    filenames = Enum.map(assets, &elem(&1, 0))
    duplicates = Enum.uniq(filenames -- Enum.uniq(filenames))

    if duplicates != [] do
      duplicates = duplicates |> Enum.map(&inspect/1) |> Enum.join(", ")

      IO.warn(
        "found duplicate assets in #{inspect(env.module)}: #{duplicates}",
        Macro.Env.stacktrace(env)
      )
    end

    if assets != [] and "main.js" not in filenames do
      IO.warn(
        ~s'missing required asset "main.js" in #{inspect(env.module)}',
        Macro.Env.stacktrace(env)
      )
    end

    assets = Enum.uniq_by(assets, &elem(&1, 0))

    dir = dir_for_module(env.module)
    File.rm_rf!(dir)
    File.mkdir_p!(dir)

    hash = assets_hash(assets)
    archive_path = __assets_archive_path__(env.module, hash)
    package_assets!(assets, archive_path)

    quote do
      def __assets_info__() do
        %{
          archive_path: Kino.JS.__assets_archive_path__(__MODULE__, unquote(hash)),
          js_path: "main.js",
          hash: unquote(hash)
        }
      end

      # Force recompilation if new assets are added
      def __mix_recompile__? do
        current_paths = Kino.JS.__paths__(unquote(assets_path))
        :erlang.md5(current_paths) != unquote(:erlang.md5(asset_paths))
      end
    end
  end

  def __paths__(nil), do: []

  def __paths__(path) do
    Path.join(path, "**")
    |> Path.wildcard()
    |> Enum.reject(&File.dir?/1)
    |> Enum.map(&String.replace_leading(&1, path <> "/", ""))
    |> Enum.sort()
  end

  defp package_assets!(assets, archive_path) do
    archive_content =
      for {filename, content} <- assets, do: {String.to_charlist(filename), content}

    :ok = :erl_tar.create(archive_path, archive_content, [:compressed])
  end

  defp assets_hash(assets) do
    md5_hash =
      assets
      |> Enum.sort()
      |> Enum.flat_map(&Tuple.to_list/1)
      |> :erlang.md5()

    Base.encode32(md5_hash, case: :lower, padding: false)
  end

  def __assets_archive_path__(module, hash) do
    dir = dir_for_module(module)
    Path.join(dir, hash <> ".tar.gz")
  end

  defp dir_for_module(module) do
    priv_dir = :code.priv_dir(:kino)
    module_dir = module |> Module.split() |> Enum.join("_")
    Path.join([priv_dir, "assets", module_dir])
  end

  @doc """
  Instantiates a static JavaScript kino defined by `module`.

  The given `data` is passed directly to the JavaScript side during
  initialization.

  ## Options

    * `:export_info_string` - used as the info string for the Markdown
      code block where output data is persisted

    * `:export_key` - in case the data is a map and only a specific part
      should be exported

  ## Export

  The output can optionally be exported in notebook source by specifying
  `:export_info_string`. For example:

      data = "graph TD;A-->B;"
      Kino.JS.new(__MODULE__, data, export_info_string: "mermaid")

  Would be rendered as the following Live Markdown:

  ````markdown
  ```mermaid
  graph TD;A-->B;
  ```
  ````

  Non-binary data is automatically serialized to JSON.
  """
  @spec new(module(), term(), keyword()) :: t()
  def new(module, data, opts \\ []) do
    export =
      if info_string = opts[:export_info_string] do
        export_key = opts[:export_key]

        if export_key do
          unless is_map(data) do
            raise ArgumentError,
                  "expected data to be a map, because :export_key is specified, got: #{inspect(data)}"
          end

          unless is_map_key(data, export_key) do
            raise ArgumentError,
                  "got :export_key of #{inspect(export_key)}, but no such key found in data: #{inspect(data)}"
          end
        end

        %{info_string: info_string, key: export_key}
      end

    ref = Kino.Output.random_ref()

    Kino.JS.DataStore.store(ref, data)

    Kino.Bridge.reference_object(ref, self())
    Kino.Bridge.monitor_object(ref, Kino.JS.DataStore, {:remove, ref})

    %__MODULE__{module: module, ref: ref, export: export}
  end

  @doc false
  @spec js_info(t()) :: Kino.Output.js_info()
  def js_info(%__MODULE__{} = kino) do
    %{
      js_view: %{
        ref: kino.ref,
        pid: Kino.JS.DataStore.cross_node_name(),
        assets: kino.module.__assets_info__()
      },
      export: kino.export
    }
  end
end
