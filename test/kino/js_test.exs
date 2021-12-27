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
end
