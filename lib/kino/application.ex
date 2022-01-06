defmodule Kino.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Kino.DynamicSupervisor},
      Kino.SubscriptionManager,
      Kino.JSDataStore,
      Kino.Terminator
    ]

    opts = [strategy: :one_for_one, name: Kino.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
