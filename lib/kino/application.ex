defmodule Kino.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Kino.SmartCell.register(Kino.SmartCell.DBConnection)

    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Kino.DynamicSupervisor},
      Kino.SubscriptionManager,
      Kino.JS.DataStore,
      Kino.Terminator
    ]

    opts = [strategy: :one_for_one, name: Kino.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
