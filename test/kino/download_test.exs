defmodule Kino.DownloadTest do
  use ExUnit.Case, async: true

  describe "start/3" do
    test "returns %Kino.JS{} " do
      assert %Kino.JS{module: Kino.Download} =
               Kino.Download.start("data.json", fn -> ~s/{"foo" => "bar"}/ end)
    end
  end
end
