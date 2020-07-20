defmodule UnderscoreEx.Command.Creajam do
  @moduledoc false
  use UnderscoreEx.Command
  alias UnderscoreEx.Repo
  alias UnderscoreEx.Schema
  require Logger

  @impl true
  def predicates, do: [UnderscoreEx.Predicates.guild([684_401_012_345_536_593])]

  @impl true
  defdelegate call(context, args), to: UnderscoreEx.Command.GroupHelper

  def handle_reaction(:add, %{
        channel_id: channel_id,
        message_id: message_id,
        emoji: %{id: emoji_id},
        guild_id: guild_id,
        user_id: user_id
      }) do
    import Ecto.Query

    config = Application.get_env(:underscore_ex, Creajam)

    if channel_id === config[:theme] and
         emoji_id === config[:action_emoji] do
      Schema.Creajam
      |> where(theme_message_id: ^message_id)
      |> Repo.one()
      |> case do
        %Schema.Creajam{} ->
          %{roles: roles} = Nostrum.Api.get_guild_member!(guild_id, user_id)

          Nostrum.Api.modify_guild_member!(guild_id, user_id,
            roles: [config[:participant_role] | roles] |> Enum.uniq()
          )

        nil ->
          :ok
      end
    end
  end

  def handle_reaction(_type, _data) do
    :ok
  end

  def init do
    Logger.info("Initialising creajam")

    :erlcron.cron(
      :weekly_theme_new,
      {{:weekly, :mon, {0, :am}}, {UnderscoreEx.Command.Creajam, :debug, ["new theme"]}}
    )

    :erlcron.cron(
      :weekly_theme_archive,
      {{:weekly, :sun, {11, 42, :pm}}, {UnderscoreEx.Command.Creajam, :debug, ["archive theme"]}}
    )
  end

  def debug(message) do
    IO.inspect(message)
  end

  def generate_theme() do
    ["adjectives.txt", "nouns.txt"]
    |> Enum.map(fn file ->
      File.read!("./resources/#{file}") |> String.split("\n") |> Enum.random()
    end)
    |> Enum.join(" ")
  end

  def new_theme(opts \\ []) do
    config = Application.get_env(:underscore_ex, Creajam)

    sub_cat = Nostrum.Cache.ChannelCache.get!(config[:rendu])

    guild = Nostrum.Cache.GuildCache.get!(sub_cat.guild_id)

    theme = if is_nil(opts[:theme]), do: generate_theme(), else: opts[:theme]

    channel =
      if is_nil(opts[:channel_id]) do
        Nostrum.Api.create_guild_channel!(guild.id,
          parent_id: sub_cat.id,
          name: theme,
          topic: theme
        )
      else
        chan = Nostrum.Cache.ChannelCache.get!(opts[:channel_id])

        Nostrum.Api.modify_channel!(chan.id,
          parent_id: sub_cat.id,
          permission_overwrites: sub_cat.permission_overwrites,
          topic: theme,
          name: theme
        )
      end

    number = get_current_number!() + 1

    Nostrum.Api.modify_guild_role!(guild.id, config[:ping_role], mentionable: true)

    message =
      Nostrum.Api.create_message!(config[:theme], %{
        content: if(Mix.env() === :dev, do: "@ping", else: "<@&#{config[:ping_role]}>"),
        embed: %Nostrum.Struct.Embed{
          title:
            Timex.now("Europe/Paris")
            |> Timex.format!("Creajam ##{number}, annee {YYYY} semaine {Wiso}"),
          description: """
          Le theme est \"#{theme}\"
          Le rendu se fait dans <##{channel.id}>
          Reagissez avec <:emoji:#{config[:action_emoji]}> pour indiquer votre envie de participer
          """
        }
      })

    Nostrum.Api.modify_guild_role!(guild.id, config[:ping_role], mentionable: false)

    Nostrum.Api.create_reaction!(message.channel_id, message.id, "emoji:#{config[:action_emoji]}")

    Repo.insert!(%Schema.Creajam{
      theme_channel_id: message.channel_id,
      theme_message_id: message.id,
      submit_channel_id: channel.id,
      theme: theme,
      is_test: Mix.env() === :dev,
      number: number
    })

    :ok
  rescue
    e -> e |> IO.inspect() |> inspect()
  end

  def get_submissions!(channel_id) do
    Nostrum.Api.get_channel_messages!(channel_id, :infinity)
    |> Enum.group_by(fn %{author: %{id: id}} -> id end)
    |> Enum.map(fn {_mid, [%{author: author} | _]} -> Nostrum.Struct.User.mention(author) end)
  end

  def get_current_number!() do
    import Ecto.Query

    Schema.Creajam
    |> where(is_test: false)
    |> last(:number)
    |> Repo.one()
    |> case do
      %{number: number} -> number
      _ -> 0
    end
  end

  def archive_theme do
    config = Application.get_env(:underscore_ex, Creajam)

    sub_cat = Nostrum.Cache.ChannelCache.get!(config[:rendu])

    archive_cat = Nostrum.Cache.ChannelCache.get!(config[:archive])

    guild = Nostrum.Cache.GuildCache.get!(sub_cat.guild_id)

    guild.channels
    |> Enum.filter(fn {_, %{parent_id: parent_id}} -> parent_id === sub_cat.id end)
    |> Enum.each(fn {id, _} ->
      import Ecto.Query

      Schema.Creajam
      |> where(submit_channel_id: ^id, is_test: ^(Mix.env() === :dev))
      |> Repo.one()
      |> case do
        %Schema.Creajam{} = jam ->
          Nostrum.Api.modify_channel!(id,
            parent_id: archive_cat.id,
            permission_overwrites: archive_cat.permission_overwrites
          )

          subs = get_submissions!(id)
          participation_count = subs |> length()

          Schema.Creajam.changeset(jam, %{participation_count: participation_count, ended: true})
          |> Repo.update!()

          message = Nostrum.Api.get_channel_message!(jam.theme_channel_id, jam.theme_message_id)

          embed = %Nostrum.Struct.Embed{
            (message.embeds
             |> hd())
            | fields: [
                %Nostrum.Struct.Embed.Field{
                  name: "Inscriptions",
                  value:
                    guild.members
                    |> Enum.filter(fn {_, %{roles: roles}} ->
                      config[:participant_role] in roles
                    end)
                    |> length(),
                  inline: true
                },
                %Nostrum.Struct.Embed.Field{
                  name: "Participations",
                  value: participation_count,
                  inline: true
                },
                %Nostrum.Struct.Embed.Field{
                  name: "Participants",
                  value:
                    case subs do
                      [] -> "Personne :("
                      subs -> subs |> Enum.join(" ")
                    end
                }
              ],
              footer: %Nostrum.Struct.Embed.Footer{
                text: "Cette jam est terminee"
              }
          }

          Nostrum.Api.edit_message!(jam.theme_channel_id, jam.theme_message_id, embed: embed)
          Nostrum.Api.delete_all_reactions!(jam.theme_channel_id, jam.theme_message_id)

        _ ->
          :ok
      end
    end)

    guild.members
    |> Enum.each(fn {id, %{roles: roles}} ->
      if config[:participant_role] in roles do
        fn ->
          Nostrum.Api.modify_guild_member(guild.id, id,
            roles: roles -- [config[:participant_role]]
          )
        end
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> UnderscoreEx.Util.bulk()

    :ok
  rescue
    e -> e |> IO.inspect() |> inspect()
  end

  defmodule RerollMeme do
    @moduledoc false
    use UnderscoreEx.Command

    @impl true
    defdelegate predicates, to: UnderscoreEx.Command.Creajam

    @impl true
    def call(_context, _args), do: "Ok chef, on reroll"
  end

  defmodule NoRerollMeme do
    @moduledoc false
    use UnderscoreEx.Command

    @impl true
    defdelegate predicates, to: UnderscoreEx.Command.Creajam

    @impl true
    def call(_context, _args), do: "Ok chef, on reroll plus"
  end

  defmodule GenTheme do
    @moduledoc false
    use UnderscoreEx.Command

    @impl true
    defdelegate predicates, to: UnderscoreEx.Command.Creajam

    @impl true
    def call(_context, _args), do: UnderscoreEx.Command.Creajam.generate_theme()
  end
end
