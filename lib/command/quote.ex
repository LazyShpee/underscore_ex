defmodule UnderscoreEx.Command.Quote do
  use UnderscoreEx.Command

  def handle_reaction(
        :add,
        %{
          emoji: %{name: "📋"},
          guild_id: guild_id,
          channel_id: channel_id,
          message_id: message_id,
          user_id: user_id
        }
      ) do
    :ets.insert(
      :quotes,
      {user_id,
       %{guild_id: guild_id, channel_id: channel_id, message_id: message_id, user_id: user_id}}
    )
  end

  def handle_reaction(_, _), do: :noop

  @impl true
  def usage(),
    do: [
      "[discord message link]"
    ]

  @impl true
  def description,
    do: """
    Quotes a message from a given discord message url (eg. https://discord.com/channels/0000000000/0000000000/0000000000)
    If no url is given, it will quote the last message you've reacted to with 📋
    """

  @impl true
  def parse_args(args), do: args

  @impl true
  def call(%{message: %{author: %{id: id}}}, "") do
    with [{^id, %{guild_id: guild_id, channel_id: channel_id, message_id: message_id}}] <-
           :ets.lookup(:quotes, id),
         {:ok, embed} <- make_embed(guild_id, channel_id, message_id) do
      [
        embed: embed
      ]
    else
      e ->
        IO.inspect(e)
        :noop
    end
  end

  @impl true
  def call(%{message: %{author: %{id: _id}}}, url) do
    with %{"guild_id" => guild_id, "channel_id" => channel_id, "message_id" => message_id} <-
           decode_message_url(url),
         {:ok, embed} <-
           make_embed(
             guild_id |> String.to_integer(),
             channel_id |> String.to_integer(),
             message_id |> String.to_integer()
           ) do
      [
        embed: embed
      ]
    else
      e ->
        IO.inspect(e)
        :noop
    end
  end

  defp make_embed(guild_id, channel_id, message_id) do
    with {:ok, message} <- Nostrum.Api.get_channel_message(channel_id, message_id) do
      import Nostrum.Struct.Embed

      embed =
        %Nostrum.Struct.Embed{}
        |> put_description(message.content)
        |> put_author(
          message.author.username,
          nil,
          message.author |> Nostrum.Struct.User.avatar_url("png")
        )
        |> put_timestamp(message.timestamp)
        |> put_field(
          "Original",
          "[Jump!](#{%{message | guild_id: guild_id} |> encode_message_url()})",
          false
        )

      embed =
        with {:ok, %Nostrum.Struct.Guild{name: guild_name} = guild} <-
               Nostrum.Api.get_guild(guild_id),
             {:ok, %Nostrum.Struct.Channel{name: channel_name}} <-
               Nostrum.Api.get_channel(channel_id) do
          embed
          |> put_footer(
            "On #{guild_name} | ##{channel_name}",
            guild |> Nostrum.Struct.Guild.icon_url("png")
          )
        else
          _ -> embed
        end

      embed =
        with [%Nostrum.Struct.Embed{type: "image", url: url} | _] <- message.embeds,
             false <- url_spoilered?(message.content, url) do
          embed |> put_image(url)
        else
          _ -> embed
        end

      embed =
        with [%Nostrum.Struct.Message.Attachment{filename: filename, url: url} | _] <-
               message.attachments,
             spoiler <- filename |> String.starts_with?("SPOILER_") do
          embed =
            if filename |> String.ends_with?([".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp"]) and
                 not spoiler,
               do: embed |> put_image(url),
               else: embed

          case spoiler do
            true -> embed |> put_field("Attachment", "||[#{filename}](#{url})||")
            false -> embed |> put_field("Attachment", "[#{filename}](#{url})")
          end
        else
          _ -> embed
        end

      {:ok, embed}
    else
      _ -> :error
    end
  end

  defp url_spoilered?(text, url) do
    ~r/\|\|(.+?)\|\|/
    |> Regex.scan(text)
    |> Enum.map(&Enum.at(&1, 1))
    |> Enum.member?(url)
  end

  def decode_message_url(url) do
    ~r{^https://(canary.)?discord.com/channels/(?<guild_id>[^/]+)/(?<channel_id>[^/]+)/(?<message_id>[^/]+)$}
    |> Regex.named_captures(url)
  end

  def encode_message_url(%Nostrum.Struct.Message{
        id: message_id,
        channel_id: channel_id,
        guild_id: guild_id
      }),
      do: "https://discord.com/channels/#{guild_id}/#{channel_id}/#{message_id}"
end
