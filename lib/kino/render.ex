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

defimpl Kino.Render, for: Kino.VegaLite do
  def to_livebook(widget) do
    Kino.Output.vega_lite_dynamic(widget.pid)
  end
end

defimpl Kino.Render, for: Kino.ETS do
  def to_livebook(widget) do
    Kino.Output.table_dynamic(widget.pid)
  end
end

defimpl Kino.Render, for: Kino.DataTable do
  def to_livebook(widget) do
    Kino.Output.table_dynamic(widget.pid)
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

  defp accessible_ets_table?(reference) when is_reference(reference) do
    try do
      case :ets.info(reference, :protection) do
        :undefined -> false
        :private -> false
        _ -> true
      end
    rescue
      # When the reference is not a valid table identifier
      ArgumentError -> false
    end
  end
end

# External packages

defimpl Kino.Render, for: VegaLite do
  def to_livebook(vl) do
    spec = VegaLite.to_spec(vl)
    Kino.Output.vega_lite_static(spec)
  end
end
