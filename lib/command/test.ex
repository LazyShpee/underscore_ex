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
      {:discord, {:MESSAGE_CREATE, %{author: %{id: ^id}, channel_id: ^channel_id}}} ->
        "You sent another message :D"
    after
      5_000 ->
        "I waited for too long..."
    end
    |> Util.pipe_message(message)

    EventRegistry.unsubscribe()
  end
end
