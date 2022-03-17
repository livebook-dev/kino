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

# Kino widgets

defimpl Kino.Render, for: Kino.JS do
  def to_livebook(widget) do
    info = Kino.JS.js_info(widget)
    Kino.Bridge.reference_object(widget.ref, self())
    Kino.Output.js(info)
  end
end

defimpl Kino.Render, for: Kino.JS.Live do
  def to_livebook(widget) do
    Kino.Bridge.reference_object(widget.pid, self())
    info = Kino.JS.Live.js_info(widget)
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
  def to_livebook(widget) do
    Kino.Bridge.reference_object(widget.pid, self())
    outputs = Kino.Frame.get_outputs(widget)
    Kino.Output.frame(outputs, %{ref: widget.ref, type: :default})
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

# External packages

defimpl Kino.Render, for: VegaLite do
  def to_livebook(vl) do
    vl |> Kino.VegaLite.static() |> Kino.Render.to_livebook()
  end
end

defimpl Kino.Render, for: Postgrex.Result do
  def to_livebook(result) do
    (result.rows || [])
    |> Enum.map(&Enum.zip(result.columns, &1))
    |> Kino.DataTable.new(name: "Results")
    |> Kino.Render.to_livebook()
  end
end

defimpl Kino.Render, for: MyXQL.Result do
  def to_livebook(result) do
    (result.rows || [])
    |> Enum.map(&Enum.zip(result.columns, &1))
    |> Kino.DataTable.new(name: "Results")
    |> Kino.Render.to_livebook()
  end
end
