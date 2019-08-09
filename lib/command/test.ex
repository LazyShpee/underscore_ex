defmodule UnderscoreEx.Command.Test do
  use UnderscoreEx.Command
  alias UnderscoreEx.Core.EventRegistry
  alias UnderscoreEx.Util

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def predicates, do: [&UnderscoreEx.Predicates.bot_owner/1]

  @impl true
  def call(%{message: message}, _args) do
    "Waiting for you to reply for 5 seconds..." |> Util.pipe_message(message)
    EventRegistry.subscribe()
    id = message.author.id
    channel_id = message.channel_id

    receive do
      {:discord, {:MESSAGE_REACTION_ADD, stuff}} ->
        # %{channel_id: 220746476542885899, emoji: %{animated: false, id: nil, name: "™"}, guild_id: 179391900669837312, message_id: 609395005550755843, user_id: 87574389666611200}
        "```elixir\n#{inspect(stuff)}\n```"
    after
      5_000 ->
        "I waited for too long..."
    end
    |> Util.pipe_message(message)

    EventRegistry.unsubscribe()
  end
end
