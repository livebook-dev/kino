defmodule Kino.JSTest do
  use ExUnit.Case, async: true

  test "packages inline assets" do
    js_info = Kino.TestModules.JSInlineAssets.__js_info__()

    assert {:ok, files} = :erl_tar.extract(js_info.assets.archive_path, [:memory, :compressed])
    assert [{'main.css', "body {" <> _}, {'main.js', "export function init(" <> _}] = files
  end

  test "packages external assets" do
    js_info = Kino.TestModules.JSExternalAssets.__js_info__()

    assert {:ok, files} = :erl_tar.extract(js_info.assets.archive_path, [:memory, :compressed])
    assert [{'main.css', "body {" <> _}, {'main.js', "export function init(" <> _}] = files
  end
end
