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

# External packages

defimpl Kino.Render, for: VegaLite do
  def to_livebook(vl) do
    spec = VegaLite.to_spec(vl)
    Kino.Output.vega_lite_static(spec)
  end
end
