defprotocol Kino.Render do
  @moduledoc """
  Protocol defining term formatting in the context of Livebook.
  """

  @fallback_to_any true

  @doc """
  Transforms the given value into a Livebook-compatible output.

  For detailed description of the output format see `t:Livebook.Runtime.output/0`.

  When implementing the protocol for custom struct, you generally do
  not need to worry about the output format. Instead, you can compose
  built-in kinos and call `Kino.Render.to_livebook/1` to get the
  expected representation.

  For example, if we wanted to render a custom struct as a mermaid
  graph, we could do this:

      defimpl Kino.Render, for: Graph do
        def to_livebook(graph) do
          source = Graph.to_mermaid(graph)
          mermaid_kino = Kino.Mermaid.new(source)
          Kino.Render.to_livebook(mermaid_kino)
        end
      end

  In many cases it is useful to show the default inspect representation
  alongside our custom visual representation. For this, we can use tabs:

      defimpl Kino.Render, for: Graph do
        def to_livebook(graph) do
          source = Graph.to_mermaid(graph)
          mermaid_kino = Kino.Mermaid.new(source)
          inspect_kino = Kino.Inspect.new(graph)
          kino = Kino.Layout.tabs(Graph: mermaid_kino, Raw: inspect_kino)
          Kino.Render.to_livebook(kino)
        end
      end

  """
  @spec to_livebook(t()) :: map()
  def to_livebook(value)
end

defimpl Kino.Render, for: Any do
  def to_livebook(term) do
    Kino.Output.inspect(term)
  end
end

defimpl Kino.Render, for: Kino.Inspect do
  def to_livebook(raw) do
    Kino.Render.Any.to_livebook(raw.term)
  end
end

defimpl Kino.Render, for: Kino.JS do
  @dialyzer {:nowarn_function, {:to_livebook, 1}}

  def to_livebook(kino) do
    Kino.Bridge.reference_object(kino.ref, self())
    %{js_view: js_view, export: export} = Kino.JS.output_attrs(kino)
    %{type: :js, js_view: js_view, export: export}
  end
end

defimpl Kino.Render, for: Kino.JS.Live do
  @dialyzer {:nowarn_function, {:to_livebook, 1}}

  def to_livebook(kino) do
    Kino.Bridge.reference_object(kino.pid, self())
    %{js_view: js_view, export: export} = Kino.JS.Live.output_attrs(kino)
    %{type: :js, js_view: js_view, export: export}
  end
end

defimpl Kino.Render, for: Kino.Image do
  def to_livebook(image) do
    %{type: :image, content: image.content, mime_type: image.mime_type}
  end
end

defimpl Kino.Render, for: Kino.Text do
  def to_livebook(%{terminal: true} = kino) do
    %{type: :terminal_text, text: kino.text, chunk: kino.chunk}
  end

  def to_livebook(kino) do
    %{type: :plain_text, text: kino.text, chunk: kino.chunk, style: kino.style}
  end
end

defimpl Kino.Render, for: Kino.Markdown do
  def to_livebook(markdown) do
    %{type: :markdown, text: markdown.text, chunk: markdown.chunk}
  end
end

defimpl Kino.Render, for: Kino.Frame do
  @dialyzer {:nowarn_function, {:to_livebook, 1}}

  def to_livebook(kino) do
    Kino.Bridge.reference_object(kino.pid, self())
    outputs = kino |> Kino.Frame.get_items() |> Enum.map(&Kino.Render.to_livebook/1)
    %{type: :frame, ref: kino.ref, outputs: outputs, placeholder: kino.placeholder}
  end
end

defimpl Kino.Render, for: Kino.Layout do
  def to_livebook(%{type: :tabs} = kino) do
    outputs = Enum.map(kino.items, &Kino.Render.to_livebook/1)
    %{type: :tabs, outputs: outputs, labels: kino.info.labels}
  end

  def to_livebook(%{type: :grid} = kino) do
    outputs = Enum.map(kino.items, &Kino.Render.to_livebook/1)

    %{
      type: :grid,
      outputs: outputs,
      columns: kino.info.columns,
      gap: kino.info.gap,
      max_height: kino.info.max_height,
      boxed: kino.info.boxed
    }
  end
end

defimpl Kino.Render, for: Kino.Input do
  def to_livebook(input) do
    Kino.Bridge.reference_object(input.ref, self())

    %{
      type: :input,
      ref: input.ref,
      id: input.id,
      destination: input.destination,
      attrs: input.attrs
    }
  end
end

defimpl Kino.Render, for: Kino.Control do
  def to_livebook(control) do
    Kino.Bridge.reference_object(control.ref, self())

    %{
      type: :control,
      ref: control.ref,
      destination: control.destination,
      attrs: control.attrs
    }
  end
end

# Elixir built-ins

defimpl Kino.Render, for: Reference do
  def to_livebook(reference) do
    cond do
      accessible_ets_table?(reference) ->
        reference |> Kino.ETS.new() |> Kino.Render.to_livebook()

      true ->
        Kino.Render.Any.to_livebook(reference)
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
        Kino.Render.Any.to_livebook(atom)
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
        Kino.Render.Any.to_livebook(pid)
    end
  end
end

defimpl Kino.Render, for: BitString do
  def to_livebook(string) do
    case Kino.Utils.get_image_type(string) do
      nil ->
        Kino.Render.Any.to_livebook(string)

      type ->
        raw = Kino.Inspect.new(string)
        image = Kino.Image.new(string, type)
        tabs = Kino.Layout.tabs(Image: image, Raw: raw)
        Kino.Render.to_livebook(tabs)
    end
  end
end

defimpl Kino.Render, for: Nx.Heatmap do
  def to_livebook(heatmap) do
    tensor = Kino.Inspect.new(heatmap.tensor)
    heatmap = Kino.Inspect.new(heatmap)
    tabs = Kino.Layout.tabs(Heatmap: heatmap, Tensor: tensor)
    Kino.Render.to_livebook(tabs)
  end
end
