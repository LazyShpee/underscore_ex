defmodule UnderscoreEx.Command.Caca.Cancel do
  use UnderscoreEx.Command

  alias UnderscoreEx.Command.Caca

  @impl true
  defdelegate predicates, to: Caca

  @impl true
  def call(context, _args) do
    with %{discord_id: discord_id} <- Caca.get_user(context, true),
         [{^discord_id, _, _, pid}] <- :ets.take(:caca_users, discord_id) do
      Process.exit(pid, :kill)
      "Terminated your caca."
    else
      nil -> "You're not a registered caca user."
      [] -> "Found no caca stuck or ongoing."
    end
  end
end
