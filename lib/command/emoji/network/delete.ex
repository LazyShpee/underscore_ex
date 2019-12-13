defmodule UnderscoreEx.Command.Emoji.Network.Delete do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.Emoji.Network
  alias UnderscoreEx.Schema.Emoji.Guild
  alias UnderscoreEx.Schema.Emoji.Manager
  alias UnderscoreEx.Repo
  import Ecto.Query, only: [from: 2]

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def call(context, name_id) do
    with %{} = network <-
           Repo.get_by(Network, %{name_id: name_id, owner_id: "#{context.message.author.id}"}),
         {:ok, network} <- Repo.delete(network),
         {ng, _} <- from(g in Guild, where: g.network_id == ^network.id) |> Repo.delete_all(),
         {nm, _} <-
           from(m in Manager, where: m.network_id == ^network.id) |> Repo.delete_all() do
      "Emoji Network **`#{network.name_id}`** has been deleted along with its #{ng} guild#{
        (ng != 1 && "s") || ""
      } and #{nm} manager#{(nm != 1 && "s") || ""}."
    else
      nil -> "Network does not exist or does not belong to you."
      _ -> "Error occurred."
    end
  end

  @impl true
  def usage,
    do: [
      "<network name id>"
    ]
end
