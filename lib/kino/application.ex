defmodule Kino.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Application.put_env(:elixir, :dbg_callback, {Kino.Debug, :dbg, []})

    Kino.Counter.initialize()

    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Kino.DynamicSupervisor},
      Kino.SubscriptionManager,
      Kino.JS.DataStore,
      Kino.Terminator,
      {Registry, name: Kino.Debug.Registry, keys: :unique}
    ]

    opts = [strategy: :one_for_one, name: Kino.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
