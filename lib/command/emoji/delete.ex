defmodule UnderscoreEx.Command.Emoji.Delete do
  use UnderscoreEx.Command
  import UnderscoreEx.Command.Emoji
  alias UnderscoreEx.Util

  @impl true
  def parse_args(arg), do: arg

  def call(context, path) do
    {n, g, e} = resolve_emoji_path(path, context.message.guild_id)

    with {:target, [{_, target}]} <-
           {:target, get_guilds(n, g, context.message.author.id)},
         {:ok, perms} <-
           Util.guild_permissions(
             Nostrum.Cache.Me.get().id,
             target.guild_id |> String.to_integer()
           ),
         {:perms, true} <- {:perms, :manage_emojis in perms},
         {:ok, emoji} <- get_one_emoji(target.guild_id |> String.to_integer(), e),
         {:ok} <-
           Nostrum.Api.delete_guild_emoji(target.guild_id |> String.to_integer(), emoji.id) do
      "Emoji `#{emoji.name}` has been deleted."
    else
      {:target, guilds} ->
        message_not_one_guild(guilds, "**target**")

      {:error, :guild_not_found} ->
        "I'm not in one of those guilds anymore."

      {:error, :emoji_not_found} ->
        "Could not find an (unmanaged) emoji named `#{e}`."

      {:error, :too_many_emojis_found} ->
        "Too many emojis found for `#{e}`, please use the emoji id or the emoji itself instead."

      {:perms, _} ->
        "I need the `MANAGE_EMOJIS` permissions in **target** guild."
    end
  end
end
