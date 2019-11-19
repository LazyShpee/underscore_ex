defmodule UnderscoreEx.Command.Caca do
  use UnderscoreEx.Command
  alias UnderscoreEx.Repo
  alias UnderscoreEx.Schema.Caca.User
  alias UnderscoreEx.Core.EventRegistry

  @impl true
  def predicates,
    do: [
      UnderscoreEx.Predicates.syslists(["caca"])
    ]

  def get_user(
        %{message: %{author: %{id: id}, channel_id: channel_id} = message},
        silent \\ false
      ) do
    with nil <- User |> Repo.get_by(discord_id: id),
         false <- silent do
      """
      You don't have a CacaTime\\™ account.
      **If you create a user you agree that your discord id will be used to identify you and link your datas.**
      Create one now ? [y/n]
      """
      |> UnderscoreEx.Util.pipe_message(message)

      EventRegistry.subscribe()

      receive do
        {:discord,
         {:MESSAGE_CREATE, %{channel_id: ^channel_id, author: %{id: ^id}, content: content}}} ->
          case content do
            c when c in ["y", "Y"] ->
              {:ok, user} =
                User.changeset(%User{}, %{discord_id: id})
                |> Repo.insert()

              "User created." |> UnderscoreEx.Util.pipe_message(message)
              EventRegistry.unsubscribe(:nokill)
              user

            _ ->
              "Did not create user." |> UnderscoreEx.Util.pipe_message(message)
              EventRegistry.unsubscribe(if silent, do: :nokill, else: :kill)
              nil
          end
      after
        20_000 ->
          "Took too long to reply." |> UnderscoreEx.Util.pipe_message(message)
          EventRegistry.unsubscribe(if silent, do: :nokill, else: :kill)
          nil
      end
    end
  end

  @impl true
  def call(context, _args) do
    user = get_user(context)

    """
    Caca Time v0.0.0
    Your caca id is `#{user.id}`
    You are #{(!user.premium && "not ") || ""}a premium user.
    """
  end
end
