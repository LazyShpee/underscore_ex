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
        switches: [user: :string, guild: :string, channel: :string],
        aliases: [u: :user, g: :guild, c: :channel]
      )

    {options, command}
  end

  @impl true
  def call(%{message: message, prefix: prefix}, {options, command}) do
    content =
      case command |> String.trim() do
        <<"raw:", rest::binary>> -> rest
        command -> "#{prefix}#{command}"
      end

    gid = "#{options[:guild] || message.guild_id}" |> String.to_integer()

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

    UnderscoreEx.Consumer.handle_event(
      {:MESSAGE_CREATE, struct!(%Nostrum.Struct.Message{}, tmp), nil}
    )

    :ok
  end
end
