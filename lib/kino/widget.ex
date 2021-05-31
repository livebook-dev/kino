defmodule Kino.Widget do
  @moduledoc """
  A structure representing a widget process.
  """

  defstruct [:pid, :type]

  @type t :: %__MODULE__{
          pid: pid(),
          type: atom()
        }

  @doc false
  @spec start!(module(), keyword(), atom()) :: Kino.Widget.t()
  def start!(module, opts, type) do
    case DynamicSupervisor.start_child(Kino.WidgetSupervisor, {module, opts}) do
      {:ok, pid} ->
        %Kino.Widget{pid: pid, type: type}

      {:ok, pid, _info} ->
        %Kino.Widget{pid: pid, type: type}

      {:error, reason} ->
        raise RuntimeError, "failed to start #{type} widget, reason: #{inspect(reason)}"

      :ignore ->
        raise RuntimeError, "failed to start #{type} widget, reason: :ignore"
    end
  end
end
