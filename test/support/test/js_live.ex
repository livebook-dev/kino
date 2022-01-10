defmodule KinoTest.JS.Live do
  @moduledoc """
  Conveniences for testing `Kino.JS.Live` widgets.
  """

  import ExUnit.Assertions

  @doc """
  Asserts the event will be broadcasted within `timeout`.

  ## Examples

      assert_broadcast_event(widget, "bump", %{by: 2})
  """
  defmacro assert_broadcast_event(widget, event, payload, timeout \\ 100) do
    quote do
      %{ref: ref} = unquote(widget)

      assert_receive {:runtime_broadcast, "js_live", ^ref,
                      {:event, unquote(event), unquote(payload), %{ref: ^ref}}},
                     unquote(timeout)
    end
  end

  @doc """
  Sends a client event to the widget.

  ## Examples

      push_event(widget, "bump", %{"by" => 2})
  """
  def push_event(widget, event, payload) do
    send(widget.pid, {:event, event, payload, %{origin: self()}})
  end

  @doc """
  Connects to the widget and returns the initial data.

  ## Examples

      data = connect(widget)
      assert data == %{count: 1}
  """
  def connect(widget) do
    ref = widget.ref
    send(widget.pid, {:connect, self(), %{ref: ref, origin: self()}})
    assert_receive {:connect_reply, data, %{ref: ^ref}}
    data
  end

  @doc """
  An asynchronous version of `connect/1`, awaited with `await_connect/0`.

  This is useful if you need to evaluate code between sending
  the connect message and receiving the data.

  ### Examples

      async_connect(widget)
      # ...
      data = await_connect(widget)
  """
  def async_connect(widget) do
    send(widget.pid, {:connect, self(), %{origin: self(), ref: widget.ref}})
  end

  @doc """
  Awaits connection reply initiated by `async_connect/1/.
  """
  def await_connect(widget) do
    ref = widget.ref
    assert_receive {:connect_reply, data, %{ref: ^ref}}
    data
  end
end
