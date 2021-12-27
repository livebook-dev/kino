defmodule Kino.JSTest do
  use ExUnit.Case, async: true

  test "packages inline assets" do
    assets_info = Kino.TestModules.JSInlineAssets.__assets_info__()

    assert {:ok, files} = :erl_tar.extract(assets_info.archive_path, [:memory, :compressed])
    assert [{'main.css', "body {" <> _}, {'main.js', "export function init(" <> _}] = files
  end

  test "packages external assets" do
    assets_info = Kino.TestModules.JSExternalAssets.__assets_info__()

    assert {:ok, files} = :erl_tar.extract(assets_info.archive_path, [:memory, :compressed])
    assert [{'main.css', "body {" <> _}, {'main.js', "export function init(" <> _}] = files
  end

  describe "new/3" do
    test "raises an error when :export_key is specified but data is not a map" do
      assert_raise ArgumentError,
                   "expected data to be a map, because :export_key is specified, got: []",
                   fn ->
                     Kino.JS.new(Kino.TestModules.JSExternalAssets, [],
                       export_info_string: "lang",
                       export_key: :spec
                     )
                   end
    end

    test "raises an error when :export_key not in data" do
      assert_raise ArgumentError,
                   "got :export_key of :spec, but no such key found in data: %{width: 10}",
                   fn ->
                     Kino.JS.new(Kino.TestModules.JSExternalAssets, %{width: 10},
                       export_info_string: "lang",
                       export_key: :spec
                     )
                   end
    end

    test "builds export info when :export_info_string is specified" do
      widget =
        Kino.JS.new(Kino.TestModules.JSExternalAssets, %{spec: %{"width" => 10, "height" => 10}},
          export_info_string: "vega-lite",
          export_key: :spec
        )

      assert %{export: %{info_string: "vega-lite", key: :spec}} = widget
    end

    test "sets export info to nil when :export_info_string is not specified" do
      widget =
        Kino.JS.new(Kino.TestModules.JSExternalAssets, %{spec: %{"width" => 10, "height" => 10}})

      assert %{export: nil} = widget
    end
  end
end
