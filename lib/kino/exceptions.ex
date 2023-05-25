defmodule Kino.InterruptError do
  @moduledoc """
  Exception raised to stop evaluation in expected manner.
  """

  defexception [:variant, :message]

  @type t :: %__MODULE__{variant: :normal | :error, message: String.t()}
end
