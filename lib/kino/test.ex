defmodule Kino.Test do
  @moduledoc """
  Conveniences for testing custom Kino components.

  In practice, `Kino.JS.Live` kinos communicate with Livebook via
  the group leader. During tests, Livebook is out of the equation,
  so we need to mimic this side of the communication. To do so, add
  the following setup to your test module:

      import Kino.Test

      setup :configure_livebook_bridge

  """

  import ExUnit.Callbacks
  import ExUnit.Assertions

  def configure_livebook_bridge(_context) do
    gl = start_supervised!({Kino.Test.GroupLeader, self()})
    Process.group_leader(self(), gl)
    :ok
  end

  @doc """
  Asserts the given output is sent within `timeout`.

  ## Examples

      assert_output({:markdown, "_hey_"})

  """
  defmacro assert_output(output, timeout \\ 100) do
    quote do
      assert_receive {:livebook_put_output, unquote(output)}, unquote(timeout)
    end
  end

  @doc """
  Asserts the given output is sent directly to the given client within
  `timeout`.

  ## Examples

      assert_output_to("client1", {:markdown, "_hey_"})

  """
  defmacro assert_output_to(client_id, output, timeout \\ 100) do
    quote do
      assert_receive {:livebook_put_output_to, unquote(client_id), unquote(output)},
                     unquote(timeout)
    end
  end

  @doc """
  Asserts the given output is sent directly to all clients within `timeout`.

  ## Examples

      assert_output_to("client1", {:markdown, "_hey_"})

  """
  defmacro assert_output_to_clients(output, timeout \\ 100) do
    quote do
      assert_receive {:livebook_put_output_to_clients, unquote(output)}, unquote(timeout)
    end
  end

  @doc """
  Asserts a `Kino.JS.Live` kino will broadcast an event within
  `timeout`.

  ## Examples

      assert_broadcast_event(kino, "bump", %{by: 2})

  """
  defmacro assert_broadcast_event(kino, event, payload, timeout \\ 100) do
    quote do
      %{ref: ref} = unquote(kino)

      assert_receive {:runtime_broadcast, "js_live", ^ref,
                      {:event, unquote(event), unquote(payload), %{ref: ^ref}}},
                     unquote(timeout)
    end
  end

  @doc """
  Asserts a `Kino.JS.Live` kino will send an event within `timeout`
  to the caller.

  ## Examples

      assert_send_event(kino, "pong", %{})

  """
  defmacro assert_send_event(kino, event, payload, timeout \\ 100) do
    quote do
      %{ref: ref} = unquote(kino)

      assert_receive {:event, unquote(event), unquote(payload), %{ref: ^ref}}, unquote(timeout)
    end
  end

  @doc """
  Sends a client event to a `Kino.JS.Live` kino.

  ## Examples

      push_event(kino, "bump", %{"by" => 2})

  """
  def push_event(kino, event, payload) do
    send(kino.pid, {:event, event, payload, %{origin: inspect(self())}})
  end

  @doc """
  Connects to a `Kino.JS.Live` kino and returns the initial data.

  If `resolve_fun` is given, it runs after sending the connection
  request and before awaiting for the reply.

  ## Examples

      data = connect(kino)
      assert data == %{count: 1}

  """
  def connect(kino, resolve_fun \\ nil, timeout \\ 100) do
    ref = kino.ref
    send(kino.pid, {:connect, self(), %{ref: ref, origin: inspect(self())}})
    if resolve_fun, do: resolve_fun.()
    assert_receive {:connect_reply, data, %{ref: ^ref}}, timeout
    data
  end

  @doc """
  Starts a smart cell defined by the given module.

  Returns a `Kino.JS.Live` kino for interacting with the cell, as
  well as the initial source.

  ## Examples

      {kino, source} = start_smart_cell!(Kino.SmartCell.Custom, %{"key" => "value"})

  """
  def start_smart_cell!(module, attrs) do
    ref = Kino.Output.random_ref()
    spec_arg = %{ref: ref, attrs: attrs, target_pid: self()}
    %{start: {mod, fun, args}} = module.child_spec(spec_arg)
    {:ok, pid, info} = apply(mod, fun, args)

    kino = %Kino.JS.Live{module: module, pid: pid, ref: info.js_view.ref}

    {kino, info.source}
  end

  @doc ~S'''
  Asserts a smart cell update will be broadcasted within `timeout`.

  Matches against the source and attribute that are reported as part
  of the update.

  If the `source` argument is a string, that string is compared in an
  exact match against the Kino's source.

  Alternatively, the `source` argument can be used to bind a variable
  to the Kino's source, allowing for custom assertions against the
  source.

  ## Examples

      assert_smart_cell_update(kino, %{"variable" => "x", "number" => 10}, "x = 10")

      assert_smart_cell_update(kino, %{"variable" => "x", "number" => 10}, source)
      assert source =~ "10"

  '''
  defmacro assert_smart_cell_update(kino, attrs, source, timeout \\ 100) do
    quote do
      %{ref: ref} = unquote(kino)

      assert_receive {:runtime_smart_cell_update, ^ref, unquote(attrs), unquote(source), _info},
                     unquote(timeout)
    end
  end

  @doc """
  Sends a changed smart cell editor source to a `Kino.JS.Live` kino.

  This is going to call `c:Kino.SmartCell.handle_editor_change/2` implementation
  in the smart cell module.

  ## Examples

      push_smart_cell_editor_source(kino, "source code")

  """
  def push_smart_cell_editor_source(kino, source) do
    send(kino.pid, {:editor_source, source})
  end

  @doc """
  Invokes export for the given `Kino.JS` or `Kino.JS.Live` and returns
  the result.

  For more details, see `Kino.JS.new/3` and `Kino.JS.Live.new/3`
  respectively.
  """
  def export(kino, timeout \\ 100)

  def export(%Kino.JS{} = kino, timeout) do
    %{js_view: %{ref: ref, pid: pid}} = Kino.JS.output_attrs(kino)
    do_export(ref, pid, timeout)
  end

  def export(%Kino.JS.Live{} = kino, timeout) do
    %{js_view: %{ref: ref, pid: pid}} = Kino.JS.Live.output_attrs(kino)
    do_export(ref, pid, timeout)
  end

  defp do_export(ref, pid, timeout) do
    send(pid, {:export, self(), %{ref: ref}})
    assert_receive {:export_reply, export_result, %{ref: ^ref}}, timeout
    export_result
  end
end
