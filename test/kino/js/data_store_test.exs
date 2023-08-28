defmodule Kino.JS.DataStoreTest do
  use ExUnit.Case, async: true

  alias Kino.JS.DataStore

  test "replies to connect messages with stored data" do
    ref = Kino.Output.random_ref()
    data = [1, 2, 3]
    DataStore.store(ref, data, nil)

    send(DataStore, {:connect, self(), %{origin: "client1", ref: ref}})
    assert_receive {:connect_reply, ^data, %{ref: ^ref}}
  end

  test "{:remove, ref} removes data for the given ref" do
    ref = Kino.Output.random_ref()
    data = [1, 2, 3]
    DataStore.store(ref, data, nil)

    send(DataStore, {:remove, ref})

    send(DataStore, {:connect, self(), %{origin: "client1", ref: ref}})
    refute_receive {:connect_reply, _, %{ref: ^ref}}
  end

  test "replies to export messages when configured to" do
    ref = Kino.Output.random_ref()
    data = [1, 2, 3]
    export = fn data -> {"text", inspect(data)} end
    DataStore.store(ref, data, export)

    send(DataStore, {:export, self(), %{origin: "client1", ref: ref}})
    assert_receive {:export_reply, {"text", "[1, 2, 3]"}, %{ref: ^ref}}
  end
end
