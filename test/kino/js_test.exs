defmodule Kino.JSTest do
  use ExUnit.Case, async: true

  test "packages inline assets" do
    assets_info = Kino.TestModules.JSInlineAssets.__assets_info__()

    assert {:ok, files} = :erl_tar.extract(assets_info.archive_path, [:memory, :compressed])
    assert [{~c"main.css", "body {" <> _}, {~c"main.js", "export function init(" <> _}] = files
  end

  test "packages external assets" do
    assets_info = Kino.TestModules.JSExternalAssets.__assets_info__()

    assert {:ok, files} = :erl_tar.extract(assets_info.archive_path, [:memory, :compressed])
    assert [{~c"main.css", "body {" <> _}, {~c"main.js", "export function init(" <> _}] = files
  end

  describe "new/3" do
    test "sets export to true when :export is specified" do
      kino =
        Kino.JS.new(Kino.TestModules.JSExternalAssets, %{spec: %{"width" => 10, "height" => 10}},
          export: fn vl -> {"vega-lite", vl.spec} end
        )

      assert %{export: true} = kino
    end

    test "sets export to false when :export is not specified" do
      kino =
        Kino.JS.new(Kino.TestModules.JSExternalAssets, %{spec: %{"width" => 10, "height" => 10}})

      assert %{export: false} = kino
    end
  end
end
