defmodule UnderscoreEx.Command.Emoji.Network.Add.Manager do
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
         {:ok, user} <- Nostrum.Cache.UserCache.get(user_id),
         %{} = network <-
           Repo.get_by(Network, %{
             name_id: network_id,
             owner_id: "#{context.message.author.id}"
           }),
         true <- user_id != String.to_integer(network.owner_id),
         {:ok, _manager} <-
           Manager.changeset(%Manager{}, %{user_id: "#{user_id}", network_id: network.id})
           |> Repo.insert() do
      "#{user.username} as now a manager of **#{network.name}** (`#{network.name_id}`)."
    else
      {:error, %{errors: [{:user_id_network_id, {_, [{:constraint, :unique} | _]}} | _]}} ->
        "This user is already a manager."

      false ->
        "You can't add yourself as a manager."

      {:error, _} ->
        "User not found."

      nil ->
        "Network doesn't exist or isn't yours."
    end
  end

  @impl true
  def call(context, _args),
    do: UnderscoreEx.Command.Help.call(context, context.unaliased_call_name)

  @impl true
  def usage,
    do: [
      "<network name id> <user>"
    ]
end
