defmodule UnderscoreEx.Command.Emoji.Network.Remove.Guild do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.Emoji.Network
  alias UnderscoreEx.Schema.Emoji.Guild
  alias UnderscoreEx.Repo
  import Ecto.Query, only: [from: 2]

  @impl true
  def parse_args(arg),
    do:
      arg
      |> String.split(" ", parts: 2, trim: true)
      |> Enum.map(&(&1 || ""))
      |> List.to_tuple()

  @impl true
  def call(context, {network_name_id}),
    do: call(context, {network_name_id, "#{context.message.guild_id}"})

  @impl true
  def call(context, {network_name_id, guild_id}) do
    with %{} = network <-
           Repo.get_by(Network, %{
             name_id: network_name_id,
             owner_id: "#{context.message.author.id}"
           }),
         %{} = guild <-
           from(g in Guild,
             where:
               (g.guild_id == ^guild_id or g.name_id == ^guild_id) and
                 g.network_id == ^network.id
           )
           |> Repo.one(),
         {:ok, guild} <- Repo.delete(guild) do
      "Removed guild `#{guild.name_id}` from network **#{network.name}** (`#{network.name_id}`)."
    else
      nil -> "Either the network or guild doesn't exist, or the network isn't yours."
      _ -> "Error occurred."
    end
  end

  @impl true
  def call(context, _args),
    do: UnderscoreEx.Command.Help.call(context, context.unaliased_call_name)

  @impl true
  def usage,
    do: [
      "<network name id> [guild name id or id]"
    ]
end
