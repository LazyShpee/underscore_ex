defmodule UnderscoreEx.Command.Emoji.Add do
  use UnderscoreEx.Command
  import UnderscoreEx.Command.Emoji
  alias UnderscoreEx.Util

  defp get_emoji_url_from_message(rest, message) do
    {:ok, url} = get_emoji_url(rest)

    case {url, message.attachments} do
      {"", [%{url: url} | _]} -> {:ok, url}
      {url, _} -> {:ok, url}
    end
  end

  @impl true
  def parse_args(arg),
    do:
      [_, _]
      |> destructure(arg |> String.split(" ", parts: 2, trim: true))
      |> Enum.map(&(&1 || ""))
      |> List.to_tuple()

  @impl true
  def call(context, {path, rest}) do
    {n, g, e} = resolve_emoji_path(path, context.message.guild_id)

    with {:name_format, true} <- {:name_format, valid_emoji_name?(e)},
         {:dest, [{_, dest}]} <-
           {:dest, get_guilds(n, g, context.message.author.id)},
         {:ok, perms} <-
           Util.guild_permissions(
             Nostrum.Cache.Me.get().id,
             dest.guild_id |> String.to_integer()
           ),
         {:perms, true} <- {:perms, :manage_emojis in perms},
         {:ok, emoji_url} <- get_emoji_url_from_message(rest, context.message),
         {:ok, base} <- url_to_base64(emoji_url),
         {:ok, emoji} <-
           Nostrum.Api.create_guild_emoji(dest.guild_id |> String.to_integer(),
             name: e,
             image: base
           ) do
      "Added `#{e}` to `#{dest.name_id}`. #{Nostrum.Struct.Emoji.mention(emoji)}"
    else
      {:name_format, _} ->
        "Emoji name must be between 2 and 32 characters and must only contains underscores or alphanumerical characters."

      {:dest, guilds} ->
        message_not_one_guild(guilds, "**destination**")

      {:error, :guild_not_found} ->
        "I'm not in one of those guilds anymore."

      {:perms, _} ->
        "I need the `MANAGE_EMOJIS` permissions in the **destination** guild."

      {:error, str} when is_binary(str) ->
        "Error: #{str}"

      e ->
        IO.inspect(e)

        "Unknown error occurred."
    end
  end
end
