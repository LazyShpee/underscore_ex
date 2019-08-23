defmodule UnderscoreEx.Command.Caca.Show do
  use UnderscoreEx.Command
  alias UnderscoreEx.Command.Caca
  alias UnderscoreEx.Util
  alias UnderscoreEx.Schema.Caca.{Time, User}
  alias UnderscoreEx.Repo
  import Ecto.Query

  @impl true
  defdelegate predicates, to: Caca

  @item_per_page 5

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

  def display(%User{}, {_page, _pages, 0}) do
    "Nothing here but us chickens"
  end

  def display(%User{id: id}, {page, pages, _item_count}) do
    offset = round(page - 1) * @item_per_page
    cacas =
      from(t in Time,
        where: t.user_id == ^id,
        order_by: [desc: t.t_end],
        limit: @item_per_page,
        offset: ^offset
      )
      |> Repo.all()
      |> Enum.map(&caca_format/1)
      |> Enum.join("\n")

    "Showing page #{round(page)}/#{round(pages)}\n#{cacas}"
  end

  @actions [first: "⏮", previous: "◀", next: "▶", last: "⏭", stop: "🛑"]
  @valid_emojis @actions |> Enum.map(fn {_, e} -> e end)

  @impl true
  def call(%{message: %{author: %{id: id}}} = context, _args) do
    user = Caca.get_user(context)
    item_count = Repo.one(from(t in Time, where: t.user_id == ^user.id, select: count(t.id)))
    pages = (item_count / @item_per_page) |> :math.ceil()
    page = 1
    Util.pvar({id, :page}, page)

    {:ok, message} =
      Nostrum.Api.create_message(context.message, display(user, {page, pages, item_count}))

    if item_count == 0 do
      Process.exit(self(), :kill)
    end

    @valid_emojis
    |> UnderscoreEx.Util.pipe_reactions(message)

    mid = message.id

    Util.loop(
      id,
      fn
        {ev,
         %{
           emoji: %{animated: false, id: nil, name: emoji},
           message_id: ^mid,
           user_id: ^id
         }}
        when ev in [:MESSAGE_REACTION_ADD, :MESSAGE_REACTION_REMOVE] and emoji in @valid_emojis ->
          {:ok, @actions |> Enum.find(&(elem(&1, 1) == emoji)) |> elem(0)}

        _ ->
          :ko
      end,
      fn
        :stop ->
          :halt

        action ->
          old_page = Util.pvar({id, :page})

          page =
            case action do
              :next -> old_page + 1
              :previous -> old_page - 1
              :first -> 1
              :last -> pages
            end
            |> max(1)
            |> min(pages)

          if page != old_page do
            Nostrum.Api.edit_message(message, display(user, {page, pages, item_count}))
            Util.pvar({id, :page}, page)
          end
      end
    )
  end
end
