defmodule UnderscoreEx.Util do
  @doc """
  Merges two maps recursively, keeps the right hand side in case of conflict.
  """
  @spec deep_merge(map, map) :: map
  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, left, nil) do
    left
  end

  defp deep_resolve(_key, _left, right) do
    right
  end

  alias Nostrum.Cache.GuildCache
  alias Nostrum.Api
  alias Nostrum.Struct.Guild.Member

  @min_jaro 0.62

  @doc """
  Resolves a user id from a query.

  It checks the query for the following content:
   - a raw id
   - a mention
   - a username#discriminator combo (case insensitive)
   - a similarity search against username and nickname
  """
  @spec resolve_user_id(String.t(), Nostrum.Struct.Guild.t() | integer()) ::
          {:error, atom} | {:ok, integer}
  def resolve_user_id(query, guild_id) when is_number(guild_id) do
    resolve_user_id(query, GuildCache.get!(guild_id))
  end

  def resolve_user_id(query, guild) do
    with {:error, _} <- resolve_user_id_by_raw_id(query),
         {:error, _} <- resolve_user_id_by_mention(query),
         {:error, _} <- resolve_user_id_by_tag(String.downcase(query), guild),
         do: resolve_user_id_by_similarity(query, guild)
  end

  defp resolve_user_id_by_similarity(query, guild) do
    closest_match =
      Enum.reduce(guild.members, {nil, @min_jaro}, fn {new_id, member}, {_, old_d} = old ->
        new_d =
          max(
            String.jaro_distance(query, member.user.username),
            String.jaro_distance(query, member.nick || "")
          )

        cond do
          new_d > old_d -> {new_id, new_d}
          true -> old
        end
      end)

    case closest_match do
      {nil, _} -> {:error, :not_found}
      {id, _} -> {:ok, id}
    end
  end

  defp resolve_user_id_by_raw_id(query) do
    case Regex.run(~r/^\d+$/, query) do
      [id] -> {:ok, id |> String.to_integer()}
      _ -> {:error, :not_found}
    end
  end

  defp resolve_user_id_by_mention(query) do
    case Regex.run(~r/<@!?(\d+)>/, query) do
      [_, id] -> {:ok, id |> String.to_integer()}
      _ -> {:error, :not_found}
    end
  end

  defp resolve_user_id_by_tag(query, guild) do
    case Regex.run(~r/(.+)#(\d+)/, query) do
      [_, username, discriminator] ->
        case guild.members
             |> Enum.find(fn {_, member} ->
               String.downcase(member.user.username) == String.downcase(username) &&
                 member.user.discriminator == discriminator
             end) do
          {id, _} -> {:ok, id}
          _ -> {:error, :not_found}
        end

      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Resolves a channel id from a query.

  It checks the query for the following content:
   - a raw id
   - a mention
   - a similarity search against name
  """
  @spec resolve_channel_id(String.t(), Nostrum.Struct.Guild.t() | integer) ::
          {:error, atom} | {:ok, integer}
  def resolve_channel_id(query, guild_id) when is_number(guild_id) do
    resolve_channel_id(query, GuildCache.get!(guild_id))
  end

  def resolve_channel_id(query, guild) do
    with {:error, _} <- resolve_channel_id_by_mention(query),
         {:error, _} <- resolve_channel_id_by_raw_id(query),
         do: resolve_channel_id_by_similarity(query, guild)
  end

  defp resolve_channel_id_by_mention(query) do
    case Regex.run(~r/<#(\d+)>/, query) do
      [_, id] -> {:ok, id |> String.to_integer()}
      _ -> {:error, :not_found}
    end
  end

  defp resolve_channel_id_by_raw_id(query) do
    case Regex.run(~r/(\d+)/, query) do
      [id] -> {:ok, id |> String.to_integer()}
      _ -> {:error, :not_found}
    end
  end

  defp resolve_channel_id_by_similarity(query, guild) do
    closest_match =
      Enum.reduce(guild.channels, {nil, @min_jaro}, fn {new_id, channel}, {_, old_d} = old ->
        new_d = String.jaro_distance(query, channel.name)

        cond do
          new_d > old_d -> {new_id, new_d}
          true -> old
        end
      end)

    case closest_match do
      {nil, _} -> {:error, :not_found}
      {id, _} -> {:ok, id}
    end
  end

  @doc """
  Makes a function returning {:ok, result} | {:error, error} return `result` or raise `error`.
  """
  def bangify(result) do
    case result do
      {:error, any} -> raise any
      {:ok, result} -> result
      other -> other
    end
  end

  @doc """
  Evaluates a snippet of elixir code.
  """
  @spec eval(keyword(), String.t()) :: String.t()
  def eval(env, to_eval) do
    evald =
      try do
        to_eval
        |> Code.eval_string(env, __ENV__)
      rescue
        e -> {:error, e, System.stacktrace() |> hd}
      end

    evald
    |> eval_message
  end

  defp eval_message({:error, e, stack}),
    do:
      "** (#{inspect(e.__struct__)}) #{apply(e.__struct__, :message, [e])}\n\n#{inspect(e)}\n#{
        inspect(stack)
      }"

  defp eval_message({evald, _}), do: "#{inspect(evald)}"

  @doc """
  Converts a discord snowflake (user id, channel id, role id, etc.) to a unix timestamp.
  """
  @spec snowflake_to_unix(integer) :: integer
  def snowflake_to_unix(snowflake) do
    use Bitwise
    round(((Nostrum.Constants.discord_epoch() + snowflake) >>> 22) / 1000)
  end

  @doc """
  Retrieves a members permissions within a guild.
  """
  @spec guild_permissions(integer, integer) :: {:error, atom} | {:ok, [Nostrum.Permission.t()]}
  def guild_permissions(member_id, guild_id) do
    with {:ok, guild} <- GuildCache.get(guild_id),
         member when member != nil <- Map.get(guild.members, member_id) do
      {:ok, Member.guild_permissions(member, guild)}
    else
      _ -> {:error, []}
    end
  end

  @doc """
  Retrieves a members permissions within a guild channel.
  """
  @spec channel_permissions(integer, integer, integer) ::
          {:error, atom} | {:ok, [Nostrum.Permission.t()]}
  def channel_permissions(member_id, guild_id, channel_id) do
    with {:ok, guild} <- GuildCache.get(guild_id),
         member when member != nil <- Map.get(guild.members, member_id) do
      {:ok, Member.guild_channel_permissions(member, guild, channel_id)}
    else
      _ -> {:error, :unknown_parameters}
    end
  end

  def usage(u, context) do
    "`Usage: #{context.prefix}#{context.call_name} #{u}`"
  end

  defp union(a, b) do
    a
    |> Enum.filter(&(&1 in b))
    |> Enum.sort()
  end

  def has_permissions?(user_perms, required_perms, :any) do
    length(union(user_perms, required_perms)) > 0
  end

  def has_permissions?(user_perms, required_perms, :all) do
    union(user_perms, required_perms) == Enum.sort(required_perms)
  end

  @discord_special_chars ~W(\ * _ ~ ` > <)

  @doc """
  Escapes some of discords markdown symbols
  """
  def escape_discord(str) do
    @discord_special_chars
    |> Enum.reduce(str, fn s, acc -> acc |> String.replace(s, "\\#{s}") end)
  end

  @doc """
  Unescapes some of discords markdown symbols
  """
  def unescape_discord(str) do
    @discord_special_chars
    |> Enum.reduce(str, fn s, acc -> acc |> String.replace("\\#{s}", s) end)
  end

  @doc """
  Lazily split a string into chunks of max_size at line feeds
  """
  def chunk(content, max_size \\ 2000), do: Regex.scan(~r/.{1,#{max_size}}(?:\n|$)/ms, content)

  def pipe_message(stuff, where) when is_binary(stuff),
    do:
      stuff
      |> chunk()
      |> Enum.map(&(&1 |> Enum.at(0) |> String.trim()))
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&Api.create_message(where, &1))

  def pipe_message(stuff, where), do: Api.create_message!(where, stuff)
end
