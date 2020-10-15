defmodule UnderscoreEx.Command.Role.Info do
  use UnderscoreEx.Command
  import Nostrum.Struct.Embed
  alias UnderscoreEx.Predicates

  def parse_args(arg), do: arg

  def predicates(), do: [Predicates.context(:guild)]

  def call(%{message: message}, args) do
    with {:ok, role_id} <- UnderscoreEx.Util.resolve_role_id(args, message.guild_id) do
      guild = Nostrum.Cache.GuildCache.get!(message.guild_id)

      in_role =
        guild.members
        |> Enum.filter(fn {_, %{roles: roles}} -> role_id in roles end)
        |> Enum.map(fn {_, %{user: user, nick: nick}} -> nick || user.username end)

      role = guild.roles |> Enum.find(fn {id, _} -> id == role_id end) |> elem(1)

      bool = fn
        true -> "Yes"
        false -> "No"
      end

      [
        embed:
          %Nostrum.Struct.Embed{}
          |> put_title(role.name)
          |> put_color(role.color)
          |> put_thumbnail("https://www.colorhexa.com/#{role.color |> Integer.to_string(16)}.png")
          |> put_field("ID", "#{role.id}")
          |> put_field("User count", "#{in_role |> Enum.count()}", true)
          |> put_field("Mentionable", bool.(role.mentionable), true)
          |> put_field("Hoist", bool.(role.hoist), true)
          |> put_field("Users", in_role |> Enum.join(", "))
          |> put_field(
            "Creation date",
            UnderscoreEx.Util.snowflake_to_unix(role_id)
            |> Timex.from_unix()
            |> Timex.to_datetime("Europe/Paris")
            |> Timex.format!("{YYYY}-{0M}-{0D} at {h24}:{m}")
          )
      ]
    else
      {:error, _} -> "Could not find a matching role."
    end
  end
end
