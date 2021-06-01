defprotocol Kino.Render do
  @moduledoc """
  Protocol defining term formatting in the context of Livebook.
  """

  @fallback_to_any true

  @doc """
  Transforms the given value into a Livebook-compatible output.
  """
  @spec to_output(t()) :: Kino.Output.t()
  def to_output(value)
end

defimpl Kino.Render, for: Any do
  def to_output(term) do
    Kino.Output.inspect(term)
  end
end

# Kino widgets

defimpl Kino.Render, for: Kino.VegaLite do
  def to_output(widget) do
    Kino.Output.vega_lite_dynamic(widget.pid)
  end
end

# External packages

defimpl Kino.Render, for: VegaLite do
  def to_output(vl) when is_struct(vl, VegaLite) do
    spec = VegaLite.to_spec(vl)
    Kino.Output.vega_lite_static(spec)
  end
end
