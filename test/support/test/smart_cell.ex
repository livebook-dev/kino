defmodule KinoTest.SmartCell do
  @moduledoc """
  Conveniences for testing `Kino.SmartCell` modules.
  """

  import ExUnit.Assertions

  @doc ~S'''
  Asserts a source code update will be broadcasted within `timeout`.

  ## Examples

      assert_source_update(widget, %{"variable" => "x", "number" => 10}, "x = 10")

  '''
  defmacro assert_source_update(widget, attrs, source, timeout \\ 100) do
    quote do
      %{ref: ref} = unquote(widget)

      assert_receive {:runtime_smart_cell_update, ^ref, unquote(attrs), unquote(source), _info},
                     unquote(timeout)
    end
  end

  @doc """
  Starts a smart cell defined by the given module.

  Returns a `Kino.JS.Live` widget for interacting with the cell,
  as well as the initial source.

  ## Examples

      {widget, source} = start_smart_cell!(Kino.SmartCell.Custom, %{"key" => "value"})
  """
  def start_smart_cell!(module, attrs) do
    ref = Kino.Output.random_ref()
    spec_arg = %{ref: ref, attrs: attrs, target_pid: self()}
    %{start: {mod, fun, args}} = module.child_spec(spec_arg)
    {:ok, pid, info} = apply(mod, fun, args)

    widget = %Kino.JS.Live{module: module, pid: pid, ref: info.js_view.ref}

    {widget, info.source}
  end
end
