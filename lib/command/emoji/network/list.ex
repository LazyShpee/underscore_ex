defmodule UnderscoreEx.Command.Emoji.Network.List do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.Emoji.Network
  alias UnderscoreEx.Schema.Emoji.Manager
  alias UnderscoreEx.Repo
  import Ecto.Query, only: [from: 2]

  @impl true
  def call(context, _args) do
    names =
      from(n in Network, where: n.owner_id == ^"#{context.message.author.id}")
      |> Repo.all()
      |> Enum.map(fn %{name_id: name_id, name: name} ->
        " 📁 **#{name}** (`#{name_id}`) [owner]"
      end)

    mnames =
      from(n in Network,
        join: m in Manager,
        where:
          n.id == m.network_id and m.user_id == ^"#{context.message.author.id}" and
            n.owner_id != ^"#{context.message.author.id}"
      )
      |> Repo.all()
      |> Enum.map(fn %{name_id: name_id, name: name} ->
        " 📁 **#{name}** (`#{name_id}`) [manager]"
      end)

    if length(names) + length(mnames) == 0 do
      "You have no Emoji Network."
    else
      """
      You have **#{length(names) + length(mnames)}** Emoji Network(s) :
      #{(names ++ mnames) |> Enum.join("\n")}
      """
    end
  end
end
