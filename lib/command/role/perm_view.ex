defmodule UnderscoreEx.Command.Role.PermView do
  use UnderscoreEx.Command
  # all roles, channel overrides, role for all channels, user for all channels
  def call(%{message: %{guild_id: guild_id}}, _) do
    {:ok, guild} = Nostrum.Cache.GuildCache.get(guild_id)

    guild.roles
    |> Enum.sort_by(fn {_id, %{position: position}} -> position end, &>=/2)
    |> Enum.map(fn {_id, %{permissions: permissions, name: name}} -> "#{name |> :http_uri.encode()}=#{permissions}" end)
    |> Enum.join("&")
    |> IO.inspect()

    "`:ok`"
  end
end
