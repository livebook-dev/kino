defmodule Kino.Hub do
  @moduledoc """
  Functions related to hub integrations and Livebook apps.
  """

  @type app_info ::
          %{type: :single}
          | %{:type => :multi, optional(:started_by) => user_info()}
          | %{type: :none}

  @type user_info :: %{
          id: String.t(),
          name: String.t() | nil,
          email: String.t() | nil,
          source: atom()
        }

  @doc """
  Returns information about the running app.

  Note that `:started_by` information is only available for multi-session
  apps when the app uses a Livebook Teams hub.

  Unless called from withing an app deployment, returns `%{type: :none}`.
  """
  @spec app_info() :: app_info()
  def app_info() do
    case Kino.Bridge.get_app_info() do
      {:ok, app_info} -> app_info
      {:error, _} -> %{type: :none}
    end
  end
end
