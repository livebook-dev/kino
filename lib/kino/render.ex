defprotocol Kino.Render do
  @moduledoc """
  Protocol defining term formatting in the context of Livebook.
  """

  @fallback_to_any true

  @doc """
  Transforms the given value into a Livebook-compatible output.
  """
  @spec to_livebook(t()) :: Kino.Output.t()
  def to_livebook(value)
end

defimpl Kino.Render, for: Any do
  def to_livebook(term) do
    Kino.Output.inspect(term)
  end
end

defimpl Kino.Render, for: Kino.Inspect do
  def to_livebook(raw) do
    Kino.Output.inspect(raw.term)
  end
end

defimpl Kino.Render, for: Kino.JS do
  def to_livebook(kino) do
    info = Kino.JS.js_info(kino)
    Kino.Bridge.reference_object(kino.ref, self())
    Kino.Output.js(info)
  end
end

defimpl Kino.Render, for: Kino.JS.Live do
  def to_livebook(kino) do
    Kino.Bridge.reference_object(kino.pid, self())
    info = Kino.JS.Live.js_info(kino)
    Kino.Output.js(info)
  end
end

defimpl Kino.Render, for: Kino.Image do
  def to_livebook(image) do
    Kino.Output.image(image.content, image.mime_type)
  end
end

defimpl Kino.Render, for: Kino.Markdown do
  def to_livebook(markdown) do
    Kino.Output.markdown(markdown.content)
  end
end

defimpl Kino.Render, for: Kino.Frame do
  def to_livebook(kino) do
    Kino.Bridge.reference_object(kino.pid, self())
    outputs = Kino.Frame.get_outputs(kino)
    Kino.Output.frame(outputs, %{ref: kino.ref, type: :default})
  end
end

defimpl Kino.Render, for: Kino.Layout do
  def to_livebook(%{type: :tabs} = kino) do
    Kino.Output.tabs(kino.outputs, kino.info)
  end

  def to_livebook(%{type: :grid} = kino) do
    Kino.Output.grid(kino.outputs, kino.info)
  end
end

defimpl Kino.Render, for: Kino.Input do
  def to_livebook(input) do
    Kino.Bridge.reference_object(input.attrs.ref, self())
    Kino.Output.input(input.attrs)
  end
end

defimpl Kino.Render, for: Kino.Control do
  def to_livebook(control) do
    Kino.Bridge.reference_object(control.attrs.ref, self())
    Kino.Output.control(control.attrs)
  end
end

# Elixir built-ins

defimpl Kino.Render, for: Reference do
  def to_livebook(reference) do
    cond do
      accessible_ets_table?(reference) ->
        reference |> Kino.ETS.new() |> Kino.Render.to_livebook()

      true ->
        Kino.Output.inspect(reference)
    end
  end

  defp accessible_ets_table?(tid) do
    try do
      case :ets.info(tid, :protection) do
        :undefined -> false
        :private -> false
        _ -> true
      end
    rescue
      # When the tid is not a valid table identifier
      ArgumentError -> false
    end
  end
end

defimpl Kino.Render, for: Atom do
  def to_livebook(atom) do
    cond do
      application_with_supervisor?(atom) ->
        raw = Kino.Inspect.new(atom)
        tree = Kino.Process.app_tree(atom, direction: :left_right)
        tabs = Kino.Layout.tabs(Raw: raw, "Application tree": tree)
        Kino.Render.to_livebook(tabs)

      Kino.Utils.supervisor?(atom) ->
        raw = Kino.Inspect.new(atom)
        tree = Kino.Process.sup_tree(atom, direction: :left_right)
        tabs = Kino.Layout.tabs(Raw: raw, "Supervision tree": tree)
        Kino.Render.to_livebook(tabs)

      true ->
        Kino.Output.inspect(atom)
    end
  end

  defp application_with_supervisor?(name) do
    with master when master != :undefined <- :application_controller.get_master(name),
         {root, _application} when is_pid(root) <- :application_master.get_child(master),
         do: true,
         else: (_ -> false)
  end
end

defimpl Kino.Render, for: PID do
  def to_livebook(pid) do
    cond do
      Kino.Utils.supervisor?(pid) ->
        raw = Kino.Inspect.new(pid)
        tree = Kino.Process.sup_tree(pid, direction: :left_right)
        tabs = Kino.Layout.tabs(Raw: raw, "Supervision tree": tree)
        Kino.Render.to_livebook(tabs)

      true ->
        Kino.Output.inspect(pid)
    end
  end
end
