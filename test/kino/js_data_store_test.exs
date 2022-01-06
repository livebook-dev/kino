defmodule Kino.JSDataStoreTest do
  use ExUnit.Case, async: true

  test "replies to connect messages with stored data" do
    ref = make_ref() |> inspect()
    data = [1, 2, 3]
    Kino.JSDataStore.store(ref, data)

    send(Kino.JSDataStore, {:connect, self(), %{origin: self(), ref: ref}})
    assert_receive {:connect_reply, ^data, %{ref: ^ref}}
  end

  test "replies to connect messages with nil when no matching data is found" do
    ref = make_ref() |> inspect()

    send(Kino.JSDataStore, {:connect, self(), %{origin: self(), ref: ref}})
    assert_receive {:connect_reply, nil, %{ref: ^ref}}
  end

  test "{:remove, ref} removes data for the given ref" do
    ref = make_ref() |> inspect()
    data = [1, 2, 3]
    Kino.JSDataStore.store(ref, data)

    send(Kino.JSDataStore, {:remove, ref})

    send(Kino.JSDataStore, {:connect, self(), %{origin: self(), ref: ref}})
    assert_receive {:connect_reply, nil, %{ref: ^ref}}
  end
end
