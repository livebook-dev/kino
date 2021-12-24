defmodule Kino.TestModules.JSExternalAssets do
  use Kino.JS, assets_path: Path.expand("assets", __DIR__)
end
