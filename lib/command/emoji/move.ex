defmodule UnderscoreEx.Command.Emoji.Move do
  use UnderscoreEx.Command
  import UnderscoreEx.Command.Emoji
  alias UnderscoreEx.Util

  @impl true
  def parse_args(arg),
    do:
      [_, _]
      |> destructure(arg |> String.split(" ", parts: 2, trim: true))
      |> Enum.map(&(&1 || ""))
      |> List.to_tuple()

  def call(context, {from, to}) do
    {from_n, from_g, from_e} = resolve_emoji_path(from, context.message.guild_id)
    {to_n, to_g, to_e} = resolve_emoji_path(to, context.message.guild_id)

    with {:name_format, true} <- {:name_format, valid_emoji_name?(to_e)},
         {:from, [{from_network, from}]} <-
           {:from, get_guilds(from_n, from_g, context.message.author.id)},
         {:to, [{to_network, to}]} <-
           {:to, get_guilds(to_n, to_g, context.message.author.id)},
         {:network_owner, true} <-
           {:network_owner, from_network.owner_id == to_network.owner_id},
         {:ok, emoji} <- get_one_emoji(from.guild_id |> String.to_integer(), from_e),
         {:ok, from_perms} <-
           Util.guild_permissions(
             Nostrum.Cache.Me.get().id,
             from.guild_id |> String.to_integer()
           ),
         {:ok, to_perms} <-
           Util.guild_permissions(
             Nostrum.Cache.Me.get().id,
             to.guild_id |> String.to_integer()
           ),
         {:perms, true} <- {:perms, :manage_emojis in from_perms and :manage_emojis in to_perms} do
      if from.guild_id == to.guild_id do
        case Nostrum.Api.modify_guild_emoji(from.guild_id |> String.to_integer(), emoji.id,
               name: to_e
             ) do
          {:error, err} -> "An error occurred : ```elixir\n#{inspect(err)}```"
          {:ok, new_emoji} -> "Emoji `#{emoji.name}` has been renamed `#{new_emoji.name}`."
        end
      else
        with {:ok, base} <- Nostrum.Struct.Emoji.image_url(emoji) |> url_to_base64,
             {:ok, new_emoji} <-
               Nostrum.Api.create_guild_emoji(to.guild_id |> String.to_integer(),
                 name: to_e,
                 image: base
               ),
             {:ok} <-
               Nostrum.Api.delete_guild_emoji(from.guild_id |> String.to_integer(), emoji.id) do
          "Emoji `#{from_network.name_id}/#{from.name_id}/#{emoji.name}` has been moved to `#{
            to_network.name_id
          }/#{to.name_id}/#{new_emoji.name}`."
        else
          {:error, err} -> "An error occurred : ```elixir\n#{inspect(err)}```"
        end
      end
    else
      {:network_owner, true} ->
        "Both **to** and **from** networks must belong to the same person."

      {:name_format, _} ->
        "Emoji name must be between 2 and 32 characters and must only contains underscores or alphanumerical characters."

      {:from, guilds} ->
        message_not_one_guild(guilds, "**from**")

      {:to, guilds} ->
        message_not_one_guild(guilds, "**to**")

      {:error, :guild_not_found} ->
        "I'm not in one of those guilds anymore."

      {:error, :emoji_not_found} ->
        "Could not find an (unmanaged) emoji named `#{from_e}`."

      {:error, :too_many_emojis_found} ->
        "Too many emojis found for `#{from_e}`, please use the emoji id or the emoji itself instead."

      {:perms, _} ->
        "I need the `MANAGE_EMOJIS` permissions in both **from** and **to** guilds."
    end
  end
end
