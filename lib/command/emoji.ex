defmodule UnderscoreEx.Command.Emoji do
  alias UnderscoreEx.Schema.Emoji.Manager
  alias UnderscoreEx.Schema.Emoji.Network
  alias UnderscoreEx.Schema.Emoji.Guild
  alias UnderscoreEx.Repo
  import Ecto.Query, only: [from: 2]

  def valid_emoji_name?(name), do: name |> String.match?(~r/^[a-z_0-9]{2,32}$/i)

  def get_managed_networks(user_id) do
    from(n in Network,
      preload: [guilds: ^from(g in Guild, where: is_nil(g.locked) or g.locked == false)],
      join: m in Manager,
      on: m.network_id == n.id,
      where: m.user_id == ^"#{user_id}"
    )
  end

  def get_owned_networks(user_id) do
    from(n in Network, preload: [:guilds], where: n.owner_id == ^"#{user_id}")
  end

  def get_networks(user_id) do
    from(get_managed_networks(user_id), union: ^get_owned_networks(user_id), preload: [:managers])
  end

  def get_guilds_query("", guild_id, user_id) do
    from(n in Network,
      join: g in Guild,
      join: m in Manager,
      where:
        g.network_id == n.id and
          (g.guild_id == ^guild_id or g.name_id == ^guild_id) and
          (n.owner_id == ^"#{user_id}" or (m.network_id == n.id and m.user_id == ^"#{user_id}"))
    )
  end

  def get_guilds_query(network_name_id, guild_id, user_id) do
    from([n, _, _] in get_guilds_query("", guild_id, user_id),
      where: n.name_id == ^network_name_id
    )
  end

  def get_guilds(network_name_id, guild_id, user_id) do
    from([n, g, m] in get_guilds_query(network_name_id, guild_id, user_id), select: {n, g})
    |> Repo.all()
    |> Enum.filter(fn {n, g} -> n.owner_id == "#{user_id}" or g.locked != true end)
  end

  def resolve_emoji_path(path, guild_id) do
    stuff = path |> String.split("/")
    {"#{Enum.at(stuff, -3)}", "#{Enum.at(stuff, -2) || guild_id}", "#{Enum.at(stuff, -1)}"}
  end

  def message_not_one_guild([], what) do
    "No matching #{what} guild found, please make sure it exists and you have managing rights."
  end

  def message_not_one_guild(guilds, what) do
    formatted_guilds =
      guilds
      |> Enum.map(fn {n, g} -> " - **`#{g.name_id}`** in **#{n.name}** (`#{n.name_id}`)" end)

    "Too many matching #{what} guild found :\n#{formatted_guilds |> Enum.join("\n")}"
  end

  def get_one_emoji(guild_id, query) do
    emoji_id =
      [~r/<a?:[^:]+:(\d+)>/, ~r|https://cdn.discordapp.com/emojis/(\d+)(?:\?.*)?|, ~r/(\d{15,})/]
      |> Enum.reduce_while(0, fn r, acc ->
        case r |> Regex.run(query) do
          [_, id] -> {:halt, id |> String.to_integer()}
          nil -> {:cont, acc}
        end
      end)

    emoji_name =
      case ~r/<a?:([^:]+):\d+>/ |> Regex.run(query) do
        [_, name] -> name
        _ -> query
      end

    with {:ok, %{emojis: emojis}} <- Nostrum.Cache.GuildCache.get(guild_id),
         [emoji] <-
           Enum.filter(emojis, fn e ->
             e.name == emoji_name or (e.id == emoji_id and e.managed != true)
           end) do
      {:ok, emoji}
    else
      {:error, _} -> {:error, :guild_not_found}
      [] -> {:error, :emoji_not_found}
      _ -> {:error, :too_many_emojis_found}
    end
  end

  @image_types ["image/png", "image/jpg", "image/gif"]
  defp valid_emoji_file(headers) do
    with {_, len} <-
           headers |> Enum.find(fn {h, _} -> h |> String.downcase() == "content-length" end),
         true <- String.to_integer(len) <= 256_000,
         {_, type} <-
           headers |> Enum.find(fn {h, _} -> h |> String.downcase() == "content-type" end),
         true <- type in @image_types do
      {:ok, type}
    else
      _ -> {:error, :too_big_or_not_image}
    end
  end

  def url_to_base64(url) do
    with {:ok, %{headers: headers}} <- HTTPoison.head(url),
         {:ok, type} <- valid_emoji_file(headers),
         {:ok, %{body: body}} <- HTTPoison.get(url) do
      {:ok, "data:#{type};base64,#{body |> Base.encode64()}"}
    else
      {:error, :too_big_or_not_image} -> {:error, "Image format not supported or too big"}
      _ -> {:error, :httpoison_error}
    end
  end

  def get_emoji_url(str) do
    with [_, a, id] <- ~r/<(a?):[^:]+:(\d+)>/ |> Regex.run(str) do
      {:ok, "https://cdn.discordapp.com/emojis/#{id}.#{if a == "", do: "png", else: "gif"}"}
    else
      _ -> {:ok, str}
    end
  end
end
