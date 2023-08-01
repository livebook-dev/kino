defmodule Kino.ShortsTest do
  use ExUnit.Case, async: true

  import Kino.Shorts

  test "data_table" do
    assert %Kino.JS.Live{} = data_table([%{foo: 1}])
  end

  test "download" do
    assert %Kino.JS.Live{} = download(fn -> "hello" end)
  end

  test "mermaid" do
    assert %Kino.JS{} = Kino.Mermaid.new("foo")
  end

  test "frame" do
    assert %Kino.Frame{} = frame()
  end

  test "html" do
    assert %Kino.JS{} = html("foo")
  end

  test "tabs" do
    assert tabs(foo: "foo", bar: "bar") == Kino.Layout.tabs(foo: "foo", bar: "bar")
  end

  test "grid" do
    assert grid(["foo", "bar"]) == Kino.Layout.grid(["foo", "bar"])
  end

  test "markdown" do
    assert markdown("foo") == Kino.Markdown.new("foo")
  end

  test "text" do
    assert text("foo") == Kino.Text.new("foo")
  end

  test "image" do
    assert image("foo", "image/jpg") == Kino.Image.new("foo", "image/jpg")
  end
end
