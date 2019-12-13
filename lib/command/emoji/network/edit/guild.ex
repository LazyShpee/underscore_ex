defmodule UnderscoreEx.Command.Emoji.Network.Edit.Guild do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.Emoji.Network
  alias UnderscoreEx.Schema.Emoji.Guild
  alias UnderscoreEx.Repo
  import Ecto.Query, only: [from: 2]

  @impl true
  def parse_args(arg),
    do:
      [_, _, _, _]
      |> destructure(arg |> String.split(" ", parts: 4, trim: true))
      |> Enum.map(&(&1 || ""))
      |> List.to_tuple()

  @impl true
  @editable [:name_id, :locked]
  def call(context, {network_id, guild_id, key_str, value_str}) do
    key = String.to_atom(key_str)

    with true <- key in @editable,
         %{^key => old} = guild <-
           from(g in Guild,
             join: n in Network,
             where:
               (g.guild_id == ^guild_id or g.name_id == ^guild_id) and
                 n.id == g.network_id and n.name_id == ^network_id and
                 n.owner_id == ^"#{context.message.author.id}",
             select: g
           )
           |> Repo.one(),
         {:ok, %{^key => new}} <- Guild.changeset(guild, %{key => value_str}) |> Repo.update() do
      "📝 Edited `#{key}` : `#{old || "<nothing>"}` -> `#{new}`."
    else
      nil ->
        "This guild doesn't exist or isn't yours."

      false ->
        "Key must be one of #{@editable |> Enum.map(&"`#{&1}`") |> Enum.join(", ")}."

      {:error, %{errors: [{:name_id_network_id, {_, [{:constraint, :unique} | _]}} | _]}} ->
        "This guild id is already taken in this network."

      {:error, %{errors: [{:name_id, {_, [{:validation, :format} | _]}} | _]}} ->
        "Guild id is not valid."
    end
  end

  @impl true
  def call(context, _args), do: UnderscoreEx.Command.Help.call(context, context.unaliased_call_name)

  @impl true
  def usage,
    do: [
      "<network id> <guild id> <key> [value]"
    ]
end
