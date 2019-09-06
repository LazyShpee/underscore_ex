defmodule UnderscoreEx.Application do
  @moduledoc false

  use Application

  alias UnderscoreEx.Consumer

  def start(_type, _args) do
    :ets.new(:caca_users, [:set, :public, :named_table])
    :ets.new(:loop_users, [:set, :public, :named_table])
    :ets.new(:states, [:set, :public, :named_table])
    TIO.init()

    children =
      [
        UnderscoreEx.Repo,
        UnderscoreEx.Core.EventRegistry,
        UnderscoreEx.Core
      ] ++
        for i <- 1..System.schedulers_online(), do: Supervisor.child_spec({Consumer, []}, id: i)

    opts = [strategy: :one_for_one, name: UnderscoreEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
