defmodule Kino.Widget do
  @moduledoc false

  @doc false
  @spec start!(module(), keyword()) :: pid()
  def start!(module, opts) do
    case DynamicSupervisor.start_child(Kino.WidgetSupervisor, {module, opts}) do
      {:ok, pid} ->
        pid

      {:ok, pid, _info} ->
        pid

      {:error, reason} ->
        raise RuntimeError, "failed to start #{module} widget, reason: #{inspect(reason)}"

      :ignore ->
        raise RuntimeError, "failed to start #{module} widget, reason: :ignore"
    end
  end
end
