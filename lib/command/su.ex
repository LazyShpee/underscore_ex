defmodule UnderscoreEx.Command.Su do
  use UnderscoreEx.Command

  @impl true
  def predicates, do: [&UnderscoreEx.Predicates.bot_owner/1]

  @impl true
  def parse_args(arg) do
    [options, command] = arg |> String.split("--", trim: true, parts: 2)

    {options, _} =
      options
      |> OptionParser.split()
      |> OptionParser.parse!(
        switches: [user: :string, guild: :string, channel: :string, verbose: :boolean],
        aliases: [u: :user, g: :guild, c: :channel, v: :verbose]
      )

    {options, command}
  end

  defp format_context(uid, cid, gid, _message) do
    user =
      with {:ok, user} <- Nostrum.Cache.UserCache.get(uid) do
        "as #{user.username}"
      else
        _ -> "as user #{uid}"
      end

    channel =
      with {:ok, channel} <- Nostrum.Cache.ChannelCache.get(cid) do
        case channel.name do
          nil ->
            with %Nostrum.Struct.User{username: username} <- channel.recipients |> Enum.at(0) do
              "in #{username}'s DMs"
            else
              _ -> "in user DMs #{uid}"
            end

          name ->
            "in ##{name}"
        end
      else
        _ -> "in channel #{cid}"
      end

    guild =
      with false <- is_nil(gid),
           {:ok, guild} <- Nostrum.Cache.GuildCache.get(gid) do
        "in #{guild.name}"
      else
        true -> ""
        _ -> "in guild `#{gid}`"
      end

    "#{user} #{channel} #{guild}"
  end

  @impl true
  def call(%{message: message, prefix: prefix}, {options, command}) do
    {type, content} =
      case command |> String.trim() do
        <<"raw:", rest::binary>> -> {:raw, rest}
        command -> {:command, "#{prefix}#{command}"}
      end

    gid =
      case options[:guild] do
        nil -> message.guild_id
        "nil" -> nil
        id -> id |> String.to_integer()
      end

    {:ok, uid} =
      if options[:user] do
        UnderscoreEx.Util.resolve_user_id(options[:user], gid)
      else
        {:ok, message.author.id}
      end

    {:ok, cid} =
      if options[:channel] do
        UnderscoreEx.Util.resolve_channel_id(options[:channel], gid)
      else
        {:ok, message.channel_id}
      end

    tmp =
      message
      |> Map.from_struct()
      |> update_in([:author], &Map.from_struct/1)
      |> update_in([:author, :id], fn _ -> uid end)
      |> update_in([:author], &struct!(%Nostrum.Struct.User{}, &1))
      |> update_in([:content], fn _ -> "#{content}" end)
      |> update_in([:guild_id], fn _ -> gid end)
      |> update_in([:channel_id], fn _ -> cid end)

    if options[:verbose] == true do
      """
      #{if type == :raw, do: "Saying", else: "Executing command"} #{
        format_context(uid, cid, gid, message)
      }
      """
      |> UnderscoreEx.Util.pipe_message(message)
    end

    UnderscoreEx.Consumer.handle_event(
      {:MESSAGE_CREATE, struct!(%Nostrum.Struct.Message{}, tmp), nil}
    )

    :ok
  end
end
