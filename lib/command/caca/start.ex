defmodule UnderscoreEx.Command.Caca.Start do
  use UnderscoreEx.Command
  alias UnderscoreEx.Core.EventRegistry
  alias UnderscoreEx.Command.Caca
  alias UnderscoreEx.Schema.Caca.Time

  @impl true
  defdelegate predicates, to: Caca

  @finish_emoji "💩"

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def call(context, location) do
    user = Caca.get_user(context)

    # Ten minutes
    timeout = if user.premium, do: :infinity, else: 600_000
    t_start = Timex.now()
    discord_id = context.message.author.id

    with true <- :ets.insert_new(:caca_users, {discord_id, t_start, location}),
         {:ok, %{id: message_id, channel_id: channel_id} = message} <-
           Nostrum.Api.create_message(
             context.message,
             "You started a caca, react with #{@finish_emoji} to end your caca."
           ),
         {:ok} <- Nostrum.Api.create_reaction(channel_id, message_id, @finish_emoji) do
      EventRegistry.subscribe()

      reply =
        receive do
          {:discord,
           {:MESSAGE_REACTION_ADD,
            %{
              channel_id: ^channel_id,
              emoji: %{animated: false, id: nil, name: @finish_emoji},
              message_id: ^message_id,
              user_id: ^discord_id
            }}} ->
            ""
        after
          timeout -> "Max caca duration for non premium user reached."
        end

      EventRegistry.unsubscribe(:nokill)
      :ets.delete(:caca_users, discord_id)
      Nostrum.Api.edit_message!(message, reply <> "\nSaving caca...")

      t_end = Timex.now()

      Time.changeset(%Time{}, %{
        user_id: user.id,
        t_start: t_start,
        t_end: t_end,
        location: location
      })
      |> UnderscoreEx.Repo.insert!()

      Nostrum.Api.edit_message!(
        message,
        reply <>
          """
          \nSaved caca.
          Lasted #{DateTime.diff(t_end, t_start)} seconds.
          Location : #{(location == "" && "`Uknown`") || location}
          """
      )

      {:ok}
    else
      false -> "You're already in the middle of a caca."
    end
  rescue
    _ -> "An error occured..."
  end
end
