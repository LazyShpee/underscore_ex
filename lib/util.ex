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
  @spec resolve_user_id(String.t(), Nostrum.Struct.Guild.t() | integer() | nil) ::
          {:error, atom} | {:ok, integer}
  def resolve_user_id(query, guild_id) when is_number(guild_id) do
    resolve_user_id(query, GuildCache.get!(guild_id))
  end

  def resolve_user_id(query, %Nostrum.Struct.Guild{} = guild) do
    with {:error, _} <- resolve_user_id(query, nil),
         {:error, _} <- resolve_user_id_by_tag(String.downcase(query), guild),
         do: resolve_user_id_by_similarity(query, guild)
  end

  def resolve_user_id(query, nil) do
    with {:error, _} <- resolve_user_id_by_mention(query),
         do: resolve_user_id_by_raw_id(query)
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

  def resolve_guild_id(query, %Nostrum.Struct.Guild{id: guild_id}) do
    resolve_guild_id(query, guild_id)
  end

  def resolve_guild_id(<<"g:", query::binary>>, guild_id) when query in ["here", "this"] do
    {:ok, guild_id}
  end

  def resolve_guild_id(<<"g:", query::binary>>, _guild_id) do
    {:ok, query |> String.to_integer()}
  end

  def resolve_guild_id(_query, _guild_id) do
    {:error, :not_found}
  end

  @doc """
  Resolves a channel id from a query.

  It checks the query for the following content:
   - a raw id
   - a mention
   - a similarity search against name
  """
  @spec resolve_channel_id(String.t(), Nostrum.Struct.Guild.t() | integer | nil) ::
          {:error, atom} | {:ok, integer}

  def resolve_channel_id(query, %Nostrum.Struct.Guild{} = guild) do
    with {:error, _} <- resolve_channel_id(query, nil),
         do: resolve_channel_id_by_similarity(query, guild)
  end

  def resolve_channel_id(query, nil) do
    with {:error, _} <- resolve_channel_id_by_mention(query),
         do: resolve_channel_id_by_raw_id(query)
  end

  def resolve_channel_id(query, guild_id) when is_number(guild_id) do
    resolve_channel_id(query, GuildCache.get!(guild_id))
  end

  defp resolve_channel_id_by_mention(query) do
    case Regex.run(~r/<#(\d+)>/, query) do
      [_, id] -> {:ok, id |> String.to_integer()}
      _ -> {:error, :not_found}
    end
  end

  defp resolve_channel_id_by_raw_id(query) do
    case Regex.run(~r/\d+/, query) do
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
  Resolves a role id from a query.

  It checks the query for the following content:
   - a raw id
   - a mention
   - a similarity search against name
  """
  @spec resolve_role_id(String.t(), Nostrum.Struct.Guild.t() | integer | nil) ::
          {:error, atom} | {:ok, integer}

  def resolve_role_id(query, %Nostrum.Struct.Guild{} = guild) do
    with {:error, _} <- resolve_role_id(query, nil),
         do: resolve_role_id_by_similarity(query, guild)
  end

  def resolve_role_id(query, nil) do
    with {:error, _} <- resolve_role_id_by_mention(query),
         do: resolve_role_id_by_raw_id(query)
  end

  def resolve_role_id(query, guild_id) when is_number(guild_id) do
    resolve_role_id(query, GuildCache.get!(guild_id))
  end

  defp resolve_role_id_by_mention(query) do
    case Regex.run(~r/<@&(\d+)>/, query) do
      [_, id] -> {:ok, id |> String.to_integer()}
      _ -> {:error, :not_found}
    end
  end

  defp resolve_role_id_by_raw_id(query) do
    case Regex.run(~r/\d+/, query) do
      [id] -> {:ok, id |> String.to_integer()}
      _ -> {:error, :not_found}
    end
  end

  defp resolve_role_id_by_similarity(query, guild) do
    closest_match =
      Enum.reduce(guild.roles, {nil, @min_jaro}, fn {new_id, role}, {_, old_d} = old ->
        new_d = String.jaro_distance(query |> String.downcase(), role.name |> String.downcase())

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
  def eval(env, to_eval, mode \\ :inspect) do
    evald =
      try do
        to_eval
        |> Code.eval_string(env, __ENV__)
      rescue
        e -> {:error, e, __STACKTRACE__ |> hd}
      end

    evald
    |> eval_message(mode)
  end

  defp eval_message({:error, e, stack}, _mode),
    do:
      "** (#{inspect(e.__struct__)}) #{apply(e.__struct__, :message, [e])}\n\n#{inspect(e)}\n#{inspect(stack)}"

  defp eval_message({evald, _}, :inspect), do: "#{inspect(evald)}"

  defp eval_message({evald, _}, :raw), do: evald

  @doc """
  Converts a discord snowflake (user id, channel id, role id, etc.) to a unix timestamp.
  """
  @spec snowflake_to_unix(integer) :: integer
  def snowflake_to_unix(snowflake) do
    use Bitwise
    round((Nostrum.Constants.discord_epoch() + (snowflake >>> 22)) / 1000)
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

  def pipe_message(stuff, where, :pipe_only \\ :pipe_only), do: Api.create_message!(where, stuff)

  def loop(session_id, predicate \\ fn _ -> true end, callback, timeout \\ 20_000)
      when is_number(timeout) and is_function(callback) and is_function(predicate) do
    case :ets.lookup(:loop_users, session_id) do
      [] -> nil
      [{_, pid}] -> Process.exit(pid, :kill)
    end

    :ets.insert(:loop_users, {session_id, self()})
    UnderscoreEx.Core.EventRegistry.subscribe()

    result = wait_loop(predicate, callback, timeout)

    case :ets.lookup(:loop_users, session_id) do
      [] ->
        nil

      [{_, pid}] ->
        if pid == self() do
          UnderscoreEx.Core.EventRegistry.unsubscribe(:nokill)
        else
          Process.exit(pid, :kill)
        end

        :ets.delete(:loop_users, session_id)
    end

    result
  end

  defp wait_loop(predicate, callback, timeout) do
    require Logger

    time_then = DateTime.utc_now()

    receive do
      {:discord, event} ->
        try do
          case apply(predicate, [event]) do
            {:ok, data} -> apply(callback, [data])
            {:ok} -> apply(callback, [event])
            _ -> :cont_reduce_timeout
          end
          |> case do
            {:halt, result} ->
              result

            :halt ->
              :halted

            :cont_reduce_timeout ->
              time_now = DateTime.utc_now()
              time_left = DateTime.diff(time_now, time_then)

              wait_loop(
                predicate,
                callback,
                timeout - time_left * 1000
              )

            _ ->
              wait_loop(predicate, callback, timeout)
          end
        rescue
          e ->
            Logger.warn(
              "Resuming wait loop after crash\n#{inspect(e)}\n\n#{Exception.format_stacktrace(__STACKTRACE__)}"
            )

            wait_loop(predicate, callback, timeout)
        end
    after
      timeout -> :timeout
    end
  end

  def pvar(key) do
    case :ets.lookup(:states, key) |> Enum.at(0) do
      {_key, value} -> value
      _ -> nil
    end
  end

  def pvar(key, value) do
    case value do
      nil -> :ets.delete(:states, key)
      value -> :ets.insert(:states, {key, value})
    end
  end

  def pipe_reactions(reactions, message) do
    reactions
    |> Enum.intersperse(:wait)
    |> Enum.each(fn
      :wait ->
        :timer.sleep(250)

      emoji ->
        Api.create_reaction(message.channel_id, message.id, emoji)
    end)
  end

  def get_body({:ok, %HTTPoison.Response{} = reponse}), do: get_body(reponse)

  def get_body(%HTTPoison.Response{headers: headers, body: body}) do
    headers
    |> Enum.find({nil, "text/plain"}, &(elem(&1, 0) == "Content-Type"))
    |> elem(1)
    |> case do
      "application/json" -> Poison.decode!(body)
      _ -> body
    end
  end

  def request(method, url, body \\ "", header \\ [], options \\ [])

  def request(method, url, %{} = body, header, options) do
    with {:ok, body} <- Poison.encode(body) do
      HTTPoison.request(
        method,
        url,
        body,
        [{"Content-Type", "application/json"} | header],
        options
      )
    end
  end

  def request(method, url, body, header, options) do
    HTTPoison.request(method, url, body, [{"Content-Type", "application/json"} | header], options)
  end

  def bulk(actions) when is_list(actions) do
    Enum.map(actions, &bulk/1)
  end

  def bulk(action), do: bulk(action, 0)

  def bulk(action, iteration) when iteration < 3 do
    action.()
    |> case do
      {:error, %Nostrum.Error.ApiError{response: %{retry_after: ms}, status_code: 429}} ->
        receive do
        after
          ms + 50 -> bulk(action, iteration + 1)
        end

      result ->
        result
    end
  end

  def bulk(_, _) do
    {:error, :max_iteration_reached}
  end

  @zws "\u200B"

  def markdown_link_encode(info, id \\ "generic") do
    encoded =
      info
      |> :http_uri.encode()
      |> String.replace(["(", ")"], fn
        "(" -> "%28"
        ")" -> "%29"
      end)

    "[#{@zws}](https://ode.bz/__/#{id}/#{encoded})"
  end

  def markdown_link_decode(string) do
    string
    |> markdown_link_decode_raw()
    |> Enum.map(&md_link_decode/1)
  end

  defp md_link_decode("https://ode.bz/__/" <> string) do
    string
    |> String.split("/")
    |> case do
      [id, data] -> %{id: id, data: data |> :http_uri.decode()}
      _ -> md_link_decode(nil)
    end
  end

  defp md_link_decode(_) do
    %{id: "unknown", data: nil}
  end

  def markdown_link_decode_raw(string) do
    ~r/\[#{@zws}\]\(([^\)]+)\)/
    |> Regex.scan(string)
    |> Enum.map(&Enum.at(&1, 1))
  end

  def transform(list, fun) when is_list(list) do
    Enum.map(list, &transform(&1, fun))
  end

  def transform(map, fun) when is_map(map) and not is_struct(map) do
    Enum.map(map, &transform(&1, fun)) |> Map.new()
  end

  def transform({key, item}, fun) do
    {key, transform(item, fun)}
  end

  def transform(item, fun) do
    fun.(item)
  end
end
