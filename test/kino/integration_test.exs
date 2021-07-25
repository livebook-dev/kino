defmodule Kino.IntegrationTest do
  use ExUnit.Case, async: true

  @tag :tmp_dir
  test "compiles without optional deps", config do
    path = Path.join(config.tmp_dir, "foo")
    {_, 0} = System.cmd("mix", ["new", path])

    case System.cmd("mix", ["compile", "--warnings-as-errors"], cd: path) do
      {_, 0} ->
        :ok

      {contents, status} ->
        IO.puts(:stderr, contents)
        assert status == 0
    end
  end
end
