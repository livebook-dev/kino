defprotocol Kino.Transform do
  @moduledoc """
  Protocol defining term formatting in the context of Livebook.
  """

  @fallback_to_any true

  @doc """
  Transforms the given value into a Livebook-compatible output.
  """
  @spec to_livebook(t()) :: Kino.LivebookOutput.t()
  def to_livebook(value)
end

defimpl Kino.Transform, for: Any do
  def to_livebook(term) do
    Kino.LivebookOutput.inspect(term)
  end
end

# Kino widgets

defimpl Kino.Transform, for: Kino.VegaLite do
  def to_livebook(widget) do
    Kino.LivebookOutput.vega_lite_dynamic(widget.pid)
  end
end

# External packages

defimpl Kino.Transform, for: VegaLite do
  def to_livebook(vl) when is_struct(vl, VegaLite) do
    spec = VegaLite.to_spec(vl)
    Kino.LivebookOutput.vega_lite_static(spec)
  end
end
