defmodule UnderscoreEx.Command.Caca.Last do
  use UnderscoreEx.Command
  alias UnderscoreEx.Repo
  alias UnderscoreEx.Command.Caca
  alias UnderscoreEx.Schema.Caca.Time
  import Ecto.Query, only: [from: 2]

  @impl true
  defdelegate predicates, to: Caca

  def caca_format(%Time{t_end: t_end, label: label}) do
    label =
      if label == "" do
        "None"
      else
        label
      end

    time =
      t_end
      |> Timex.to_datetime("Europe/Paris")
      |> Timex.format!("{YYYY}-{0M}-{0D} at {h24}:{m}")

    "`#{time}` : #{label}"
  end

  @impl true
  def call(context, _args) do
    user = Caca.get_user(context)

    Repo.all(from(t in Time, where: t.user_id == ^user.id, order_by: [desc: t.t_end], limit: 1))
    |> Enum.map(&caca_format/1)
    |> Enum.join("\n")
  end
end
