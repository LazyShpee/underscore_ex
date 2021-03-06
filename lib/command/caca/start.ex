defmodule UnderscoreEx.Command.Caca.Start do
  use UnderscoreEx.Command
  alias UnderscoreEx.Core.EventRegistry
  alias UnderscoreEx.Command.Caca
  alias UnderscoreEx.Schema.Caca.Time

  @impl true
  defdelegate predicates, to: Caca

  @finish_emoji "💩"
  @cancel_emoji "🛑"

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def call(context, label) do
    user = Caca.get_user(context)

    timeout =
      with false <- user.premium,
           {:ok, client} <- Exredis.start_link(),
           value <- Exredis.Api.get("underscoreex:caca_timeout"),
           Exredis.stop(client),
           {n, _} <- Integer.parse(value) do
        n
      else
        true -> :infinity
        # 10 minutes
        _ -> 600_000
      end

    t_start = Timex.now()
    discord_id = context.message.author.id

    with true <- :ets.insert_new(:caca_users, {discord_id, t_start, label, self()}),
         {:ok, %{id: message_id, channel_id: channel_id} = message} <-
           Nostrum.Api.create_message(
             context.message,
             "Starting caca..."
           ),
         {:ok} <- Nostrum.Api.create_reaction(channel_id, message_id, @finish_emoji),
         :ok <- :timer.sleep(250),
         {:ok} <- Nostrum.Api.create_reaction(channel_id, message_id, @cancel_emoji) do
      Nostrum.Api.edit_message!(
        message,
        "You started a caca, react with #{@finish_emoji} to end your caca or #{@cancel_emoji} to cancel it."
      )

      EventRegistry.subscribe()

      reply =
        receive do
          {:discord,
           {:MESSAGE_REACTION_ADD,
            %{
              channel_id: ^channel_id,
              emoji: %{id: nil, name: @finish_emoji},
              message_id: ^message_id,
              user_id: ^discord_id
            }}} ->
            ""

          {:discord,
           {:MESSAGE_REACTION_ADD,
            %{
              channel_id: ^channel_id,
              emoji: %{id: nil, name: @cancel_emoji},
              message_id: ^message_id,
              user_id: ^discord_id
            }}} ->
            :cancel

          {:cancel} ->
            :cancel
        after
          timeout -> "Max caca duration for non premium user reached."
        end

      EventRegistry.unsubscribe(:nokill)
      :ets.delete(:caca_users, discord_id)

      case reply do
        :cancel ->
          Nostrum.Api.edit_message!(message, "Caca cancelled.")

        reply ->
          Nostrum.Api.edit_message!(message, reply <> "\nSaving caca...")

          t_end = Timex.now()

          Time.changeset(%Time{}, %{
            user_id: user.id,
            t_start: t_start,
            t_end: t_end,
            label: label
          })
          |> UnderscoreEx.Repo.insert!()

          Nostrum.Api.edit_message!(
            message,
            reply <>
              """
              \nSaved caca.
              Lasted #{DateTime.diff(t_end, t_start)} seconds.
              Label : #{(label == "" && "None") || label}
              """
          )
      end

      {:ok}
    else
      false -> "You're already in the middle of a caca."
    end
  rescue
    e -> "An error occured... #{inspect(e)}"
  end
end
