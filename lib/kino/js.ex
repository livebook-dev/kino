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

  All kinos require a `main.js` file that defines a JavaScript
  module and becomes the entrypoint on the client side. The
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

  The default entrypoint file is `main.js`, however you can override
  it by setting the `:entrypoint` option. The entrypoint must be a
  path relative to the assets path.

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

  ## Dependencies

  On the JavaScript side you are free to use any external packages and
  bundling tooling, as long as you provide the `main.js` file with the
  `init(ctx, data)` entrypoint. Kino itself defines a couple components
  using `Kino.JS` and we use [esbuild](https://esbuild.github.io) to
  bundle their assets, but it's entirely up to you.

  For simple components that don't require additional dependencies,
  it may be totally fine to write a single JS/CSS file without any
  bundling. Theoretically, you could even import dependencies from a
  CDN, however, we do recommend bundling dependencies with your assets
  because: (a) occasionally content from CDNs may get blocked; (b) most
  users run Livebook locally, so fetching assets from the local server
  is actually faster than fetching from a CDN; (c) nowadays many packages
  actually assume their end users use a bundler.

  To give a concrete example, let's say we want to render a graph using
  `mermaid`. We would define an NPM project at `assets/mermaid`, with
  regular `package.json` and the following `main.js` file:

  ```javascript
  import mermaid from "mermaid";

  mermaid.initialize({ startOnLoad: false });

  export function init(ctx, graph) {
    mermaid.render("graph1", graph, (svgSource, bindListeners) => {
      ctx.root.innerHTML = svgSource;
      bindListeners && bindListeners(ctx.root);
    });
  }
  ```

  Next, we would bundle the file into `lib/assets/mermaid/build/main.js`,
  and reference in our Elixir module:

      defmodule KinoDocs.Mermaid do
        use Kino.JS

        use Kino.JS, assets_path: "lib/assets/mermaid/build"

        def new(graph) do
          Kino.JS.new(__MODULE__, graph)
        end
      end

  With all that, we would use the component like so:

      KinoDocs.Mermaid.new("""
      graph TD;
        A-->B;
        A-->C;
        B-->D;
        C-->D;
      """)

  > #### Directory structure {: .info}
  >
  > Note that we intentionally suggest keeping the NPM project in the
  > `assets/` directory, but placing the bundle output in `lib/assets/`.
  > This convention ensures that you do not include the assets source
  > (including `node_modules/`) in the Hex package, but you do include
  > the bundled assets. While it is possible to specify which directories
  > are published to Hex, following the convention makes everything work
  > as expected by default.

  ## Live kinos

  So far we covered the API for defining static kinos, where the
  JavaScript side only receives the initial data and there is no
  further interaction with the Elixir side. To introduce such
  interaction, see `Kino.JS.Live` as a next step in our discussion.
  '''

  defstruct [:module, :ref, :export]

  @opaque t :: %__MODULE__{module: module(), ref: Kino.Output.ref(), export: boolean()}

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
    entrypoint = opts[:entrypoint] || "main.js"
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
      duplicates = duplicates |> Enum.map_join(", ", &inspect/1)

      IO.warn(
        "found duplicate assets in #{inspect(env.module)}: #{duplicates}",
        Macro.Env.stacktrace(env)
      )
    end

    if assets != [] and entrypoint not in filenames do
      IO.warn(
        ~s'missing required asset "#{entrypoint}" in #{inspect(env.module)}',
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

    cdn_url =
      unless any_inline_assets? do
        __cdn_url__(assets_path)
      end

    quote do
      def __assets_info__() do
        %{
          archive_path: Kino.JS.__assets_archive_path__(__MODULE__, unquote(hash)),
          js_path: unquote(entrypoint),
          hash: unquote(hash),
          cdn_url: unquote(cdn_url)
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

  def __cdn_url__(assets_path) do
    config = Mix.Project.config()

    case config[:build_scm] do
      Hex.SCM ->
        "https://repo.hex.pm/preview/#{config[:app]}/#{config[:version]}/#{assets_path}"

      Mix.SCM.Git ->
        with {revision, 0} <- System.cmd("git", ["rev-parse", "HEAD"]),
             revision <- String.trim_trailing(revision),
             {remote_url, 0} <- System.cmd("git", ["config", "--get", "remote.origin.url"]),
             remote_url <- String.trim_trailing(remote_url),
             [_, user_and_repo] <- Regex.run(~r/^.*github\.com[\/:](.*)\.git$/, remote_url) do
          "https://cdn.jsdelivr.net/gh/#{user_and_repo}@#{revision}/#{assets_path}"
        else
          _ -> nil
        end

      _scm ->
        nil
    end
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

    * `:export` - a function called to export the given kino to Markdown.
      See the "Export" section below

  ## Export

  The output can optionally be exported in notebook source by specifying
  an `:export` function. The function receives the `data` as an argument
  and should return a tuple `{info_string, payload}`. `info_string`
  is used to annotate the Markdown code block where the output is
  persisted. `payload` is the value persisted in the code block. The
  value is automatically serialized to JSON, unless it is already a
  string.

  For example:

      data = "graph TD;A-->B;"
      Kino.JS.new(__MODULE__, data, export: fn data -> {"mermaid", data} end)

  Would be rendered as the following Live Markdown:

  ````markdown
  ```mermaid
  graph TD;A-->B;
  ```
  ````

  > #### Export function {: .info}
  >
  > You should prefer to use the `data` argument for computing the
  > export payload. However, if it cannot be inferred from `data`,
  > you should just reference the original value. Do not put additional
  > fields in `data`, just to use it for export, given those fields
  > are sent to the client.
  """
  @spec new(module(), term(), keyword()) :: t()
  def new(module, data, opts \\ []) do
    opts = Keyword.validate!(opts, [:export])
    export = opts[:export]

    ref = Kino.Output.random_ref()

    Kino.JS.DataStore.store(ref, data, export)

    Kino.Bridge.reference_object(ref, self())
    Kino.Bridge.monitor_object(ref, Kino.JS.DataStore, {:remove, ref})

    %__MODULE__{module: module, ref: ref, export: export != nil}
  end

  @doc false
  @spec output_attrs(t()) :: map()
  def output_attrs(%__MODULE__{} = kino) do
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
