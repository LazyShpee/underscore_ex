defmodule UnderscoreEx.Command.Stack do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.StackItem
  alias UnderscoreEx.Repo
  import Ecto.Query

  @impl true
  def parse_args(arg),
    do: arg |> String.split(" ", parts: 2) |> Enum.map(&String.trim/1) |> List.to_tuple()

  @impl true
  def description, do: "Stack de trucs a faire qui seront peut etre jamais faits."

  @push_ops ["+", "push"]
  @pop_ops ["-", "pop"]
  @show_ops ["?", "show", "chaud"]
  @clear_ops ["clear"]

  @impl true
  def usage, do: [
    "<#{@push_ops |> Enum.join("|")}> <content>",
    "<#{@pop_ops |> Enum.join("|")}> [index]",
    "<#{@show_ops |> Enum.join("|")}>",
    "<#{@clear_ops |> Enum.join("|")}>"
  ]
  defp format_item({%{content: content, inserted_at: inserted_at}, index}) do
    _time =
      inserted_at
      |> Timex.to_datetime("Europe/Paris")
      |> Timex.format!("{YYYY}-{0M}-{0D} at {h24}:{m}")

    "`[#{String.pad_leading("#{index}", 3, "0")}] #{content}`"
  end

  # Clear
  @impl true
  def call(ctx, {op}) when op in ["clear"] do
    from(i in StackItem,
      where: i.user_id == ^ctx.message.author.id
    )
    |> Repo.delete_all()

    "C'est tout bon chef, gg"
  end

  # Add
  @impl true
  def call(ctx, {op, arg}) when op in ["+", "push"] do
    {arg, _} = arg |> String.split_at(255)

    StackItem.changeset(%StackItem{}, %{
      user_id: ctx.message.author.id,
      content:
        arg |> String.replace(["`"], "'") |> String.split(["\n"], trim: true) |> Enum.join(";")
    })
    |> Repo.insert!()

    "Ok bro, c'est push 🚀"
  end

  # Remove
  @impl true
  def call(ctx, {op}) when op in ["-", "pop"] do
    call(ctx, {op, "0"})
  end

  # Remove
  @impl true
  def call(ctx, {op, arg}) when op in ["-", "pop"] do
    with {n, _} <- Integer.parse(arg),
         [item] <-
           from(i in StackItem,
             where: i.user_id == ^ctx.message.author.id,
             order_by: [desc: i.inserted_at],
             limit: 1,
             offset: ^n
           )
           |> Repo.all() do
      item |> Repo.delete!()

      "Yes, t'as claque #{format_item({item, n})} 👏"
    else
      :error -> "Mec, donne un vrai int stp ._."
      [] -> "T'as pas autant d'items ptdr"
    end
  end

  # Show
  @impl true
  def call(ctx, {op}) when op in ["?", "show", "chaud"] do
    with items when items != [] <-
           from(i in StackItem,
             where: i.user_id == ^ctx.message.author.id,
             order_by: [desc: i.inserted_at]
           )
           |> Repo.all() do
      items
      |> Enum.with_index()
      |> Enum.map(&format_item/1)
      |> Enum.join("\n")
    else
      _ -> "T'as rien sur ta stack vrer..."
    end
  end

  @impl true
  def call(_, _), do: "Eh?"
end
