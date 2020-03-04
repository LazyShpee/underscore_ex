defmodule UnderscoreEx.Command.Creajam do
  @moduledoc false
  use UnderscoreEx.Command
  alias UnderscoreEx.Repo
  alias UnderscoreEx.Schema

  @impl true
  def predicates, do: [UnderscoreEx.Predicates.guild([684_401_012_345_536_593])]

  @impl true
  defdelegate call(context, args), to: UnderscoreEx.Command.GroupHelper

  def init do
    :erlcron.cron(
      :weekly_theme_new,
      {{:weekly, :mon, {0, :am}}, {UnderscoreEx.Command.Creajam, :new_theme, []}}
    )

    :erlcron.cron(
      :weekly_theme_archive,
      {{:weekly, :sun, {11, 42, :pm}}, {UnderscoreEx.Command.Creajam, :archive_theme, []}}
    )
  end

  def generate_theme() do
    ["adjectives.txt", "nouns.txt"]
    |> Enum.map(fn file ->
      File.read!("./resources/#{file}") |> String.split("\n") |> Enum.random()
    end)
    |> Enum.join(" ")
  end

  def new_theme do
    sub_cat =
      Nostrum.Cache.ChannelCache.get!(Application.get_env(:underscore_ex, Creajam)[:rendu])

    guild = Nostrum.Cache.GuildCache.get!(sub_cat.guild_id)

    theme = generate_theme()

    channel =
      Nostrum.Api.create_guild_channel!(guild.id,
        parent_id: Application.get_env(:underscore_ex, Creajam)[:rendu],
        name: theme,
        topic: theme
      )

    number = get_current_number!() + 1

    message =
      Nostrum.Api.create_message!(Application.get_env(:underscore_ex, Creajam)[:theme], %{
        content: "<@&#{Application.get_env(:underscore_ex, Creajam)[:ping_role]}>",
        embed: %Nostrum.Struct.Embed{
          title:
            Timex.now("Europe/Paris")
            |> Timex.format!("Creajam ##{number}, annee {YYYY} semaine {Wiso}"),
          description: "Le theme est \"#{theme}\"\nLe rendu se fait dans <##{channel.id}>"
        }
      })

    Repo.insert!(%Schema.Creajam{
      theme_channel_id: message.channel_id,
      theme_message_id: message.id,
      submit_channel_id: channel.id,
      theme: theme,
      is_test: Mix.env() === :dev,
      number: number
    })

    :ok
  catch
    _ -> "An error occured while attempting to create a new theme" |> IO.inspect()
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
      {:ok, %{number: number}} -> number
      _ -> 0
    end
  end

  def archive_theme do
    sub_cat =
      Nostrum.Cache.ChannelCache.get!(Application.get_env(:underscore_ex, Creajam)[:rendu])

    archive_cat =
      Nostrum.Cache.ChannelCache.get!(Application.get_env(:underscore_ex, Creajam)[:archive])

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

          Schema.Creajam.changeset(jam, %{participation_count: participation_count})
          |> Repo.update!()

          message = Nostrum.Api.get_channel_message!(jam.theme_channel_id, jam.theme_message_id)

          embed = %Nostrum.Struct.Embed{
            (message.embeds
             |> hd())
            | fields: [
                %Nostrum.Struct.Embed.Field{
                  name: "Participants finaux",
                  value: participation_count
                },
                %Nostrum.Struct.Embed.Field{
                  name: "Participants",
                  value: case subs do
                    [] -> "Personne :("
                    subs -> subs |> Enum.join(" ")
                  end
                }
              ]
          }

          Nostrum.Api.edit_message!(jam.theme_channel_id, jam.theme_message_id, embed: embed)

        _ ->
          :ok
      end
    end)

    :ok
  catch
    _ -> "An error occured while attempting to archive a theme" |> IO.inspect()
  end

  defmodule RerollMeme do
    @moduledoc false
    use UnderscoreEx.Command

    @impl true
    def call(_context, _args), do: "Ok chef, on reroll"
  end

  defmodule NoRerollMeme do
    @moduledoc false
    use UnderscoreEx.Command

    @impl true
    def call(_context, _args), do: "Ok chef, on reroll plus"
  end

  defmodule GenTheme do
    @moduledoc false
    use UnderscoreEx.Command

    @impl true
    def call(_context, _args), do: UnderscoreEx.Command.Creajam.generate_theme()
  end
end
