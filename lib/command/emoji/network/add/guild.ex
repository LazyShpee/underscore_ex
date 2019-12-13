defmodule UnderscoreEx.Command.Emoji.Network.Add.Guild do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.Emoji.Network
  alias UnderscoreEx.Schema.Emoji.Guild
  alias UnderscoreEx.Repo

  @impl true
  def parse_args(arg),
    do:
      arg
      |> String.split(" ", parts: 3, trim: true)
      |> Enum.map(&(&1 || ""))
      |> List.to_tuple()

  @impl true
  def call(context, {network_name_id, guild_name_id}),
    do: call(context, {network_name_id, guild_name_id, "#{context.message.guild_id}"})

  @impl true
  def call(context, {network_name_id, guild_name_id, guild_id}) do
    with {:ok, guild} <- Nostrum.Cache.GuildCache.get(guild_id |> String.to_integer()),
         true <- guild.owner_id === context.message.author.id,
         %{} = network <-
           Repo.get_by(Network, %{
             name_id: network_name_id,
             owner_id: "#{context.message.author.id}"
           }),
         {:ok, emoji_guild} <-
           Guild.changeset(%Guild{}, %{
             name_id: guild_name_id,
             guild_id: "#{guild_id}",
             network_id: network.id
           })
           |> Repo.insert() do
      "**#{guild.name}** has been added to Emoji Network **#{network.name}** (`#{network.name_id}`) as `#{
        emoji_guild.name_id
      }`."
    else
      {:error, :id_not_found_on_guild_lookup} ->
        "I am not in this guild."

      false ->
        "This guild isn't yours."

      nil ->
        "This network isn't yours or it does not exist."

      {:error, %{errors: [{:guild_id, {_, [{:constraint, :unique} | _]}} | _]}} ->
        "This guild is already in a network."

      {:error, %{errors: [{:name_id_network_id, {_, [{:constraint, :unique} | _]}} | _]}} ->
        "This guild id is already taken in this network."

      {:error, %{errors: [{:name_id, {_, [{:validation, :format} | _]}} | _]}} ->
        "Guild id is not valid."

      _ ->
        "Error occurred."
    end
  end

  @impl true
  def call(context, _args),
    do: UnderscoreEx.Command.Help.call(context, context.unaliased_call_name)

  @impl true
  def usage,
    do: [
      "<network name id> <guild name id> [guild id]"
    ]
end
