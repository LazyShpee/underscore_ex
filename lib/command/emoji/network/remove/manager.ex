defmodule UnderscoreEx.Command.Emoji.Network.Remove.Manager do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.Emoji.Network
  alias UnderscoreEx.Schema.Emoji.Manager
  alias UnderscoreEx.Repo

  @impl true
  def parse_args(args), do: args |> String.split(" ", trim: true, parts: 2)

  @impl true
  def call(context, [network_id, rest]) do
    with {:ok, user_id} <-
           UnderscoreEx.Util.resolve_user_id(rest, context.message.guild_id),
         {:network, %{} = network} <-
           {:network,
            Repo.get_by(Network, %{
              name_id: network_id,
              owner_id: "#{context.message.author.id}"
            })},
         {:manager, %{} = manager} <-
           {:manager, Repo.get_by(Manager, %{user_id: "#{user_id}", network_id: network.id})},
         {:ok, _manager} <- Repo.delete(manager) do
      user =
        case Nostrum.Cache.UserCache.get(user_id) do
          {:ok, %{username: username}} -> username
          _ -> "`#{user_id}`"
        end

      "#{user} is no longer a manager of **#{network.name}** (`#{network.name_id}`)."
    else
      {:network, nil} -> "Network doesn't exist or isn't yours."
      {:manager, nil} -> "This manager doesn't exist in this network."
      {:error, _} -> "Could not resolve user."
    end
  end

  @impl true
  def call(_context, _args), do: :noop
end
