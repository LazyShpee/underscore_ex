defmodule UnderscoreEx.Command.Emoji.List do
  use UnderscoreEx.Command

  @impl true
  def predicates, do: [UnderscoreEx.Predicates.context(:guild)]

  @impl true
  def call(%{message: %{guild_id: guild_id}}, _args) do
    %{emojis: emojis} = Nostrum.Cache.GuildCache.get!(guild_id)

    emojis
    |> Enum.map(fn e ->
      ":#{e.name |> UnderscoreEx.Util.escape_discord()}: #{Nostrum.Struct.Emoji.mention(e)}"
    end)
    |> Enum.join("\n")
  end
end
