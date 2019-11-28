defmodule UnderscoreEx.Command.Test do
  use UnderscoreEx.Command
  alias UnderscoreEx.Util

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def predicates, do: [&UnderscoreEx.Predicates.bot_owner/1]

  defp display(info), do: "Counter is currently at : #{info}."

  @impl true
  def call(%{message: %{author: %{id: id}} = message}, _args) do
    :ets.insert(:states, {{:counter, id}, 0})

    message =
      0
      |> display
      |> Util.pipe_message(message, :pipe_only)

    ["➖", "➕", "🚫"]
    |> Util.pipe_reactions(message)

    mid = message.id

    Util.loop(
      id,
      fn
        {ev,
         %{
           emoji: %{id: nil, name: emoji},
           message_id: ^mid,
           user_id: ^id
         }}
        when ev in [:MESSAGE_REACTION_ADD, :MESSAGE_REACTION_REMOVE] ->
          if emoji in ["➖", "➕", "🚫"] do
            {:ok, emoji}
          else
            :ko
          end

        _ ->
          :ko
      end,
      fn
        "🚫" ->
          {:halt, nil}

        emoji ->
          [{_, counter}] = :ets.lookup(:states, {:counter, id})

          counter =
            case emoji do
              "➖" -> counter - 1
              "➕" -> counter + 1
            end

          Nostrum.Api.edit_message!(message, display(counter))
          :ets.insert(:states, {{:counter, id}, counter})
          :cont
      end
    )
    |> case do
      :timeout -> "Timed out"
      _ -> "Halted the normal way"
    end
  end
end
