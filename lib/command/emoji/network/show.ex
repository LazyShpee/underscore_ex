defmodule UnderscoreEx.Command.Emoji.Network.Show do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.Emoji.Network
  alias UnderscoreEx.Schema.Emoji.Manager
  alias UnderscoreEx.Schema.Emoji.Guild
  alias UnderscoreEx.Repo
  import Ecto.Query, only: [from: 2]

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def call(context, name_id) do
    with %{} = network <-
           Repo.get_by(Network, %{name_id: name_id, owner_id: "#{context.message.author.id}"}),
         names <- from(g in Guild, where: g.network_id == ^network.id) |> Repo.all(),
         managers <- from(m in Manager, where: m.network_id == ^network.id) |> Repo.all() do
      formatted_names =
        names
        |> Enum.map(fn %{name_id: name_id, guild_id: guild_id, locked: locked} ->
          case Nostrum.Cache.GuildCache.get!(guild_id |> String.to_integer()) do
            nil ->
              " ⚠ `**#{name_id}**` I am not in this guild anymore"

            %{name: name, emojis: emojis} ->
              " #{(locked && "🔒") || "🔓"} **#{name}** (`#{name_id}`), #{length(emojis)} emoji(s)"
          end
        end)

      formatted_managers =
        managers
        |> Enum.map(fn m ->
          case Nostrum.Api.get_user(m.user_id |> String.to_integer()) do
            {:ok, user} -> " 👤 #{user.username}##{user.discriminator} (`#{user.id}`)"
            _ -> " ❔ `#{m.user_id}`"
          end
        end)

      """
      In network **#{network.name}** (`#{network.name_id}`) there are:
      #{
        case length(formatted_names) do
          0 -> "No guilds"
          n -> "**#{n}** guild(s):\n#{formatted_names |> Enum.join("\n")}"
        end
      }
      #{
        case length(formatted_managers) do
          0 -> "No managers"
          n -> "**#{n}** manager(s):\n#{formatted_managers |> Enum.join("\n")}"
        end
      }
      """
    else
      nil -> "Either the network doesn't exist or isn't yours."
      _ -> "Error occurred."
    end
  end
end
