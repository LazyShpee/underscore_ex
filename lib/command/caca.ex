defmodule UnderscoreEx.Command.Caca do
  use UnderscoreEx.Command
  alias UnderscoreEx.Repo
  alias UnderscoreEx.Schema.Caca.User
  alias UnderscoreEx.Core.EventRegistry

  @impl true
  def predicates,
    do: [
      fn
        %{message: %{author: %{id: id}}}
        when id in [
               # LazyShpee
               87_574_389_666_611_200,
               # Caillouche
               169_194_737_826_398_209,
               # masber
               146_071_651_857_989_633,
               # poney
               169_884_954_245_857_280
             ] ->
          :passthrough

        _ ->
          {:error, "Early access command, only beta testers can access it for now."}
      end
    ]

  def get_user(%{message: %{author: %{id: id}, channel_id: channel_id} = message}) do
    with nil <- User |> Repo.get_by(discord_id: id) do
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
            "y" ->
              {:ok, user} =
                User.changeset(%User{}, %{discord_id: id})
                |> Repo.insert()

              "User created." |> UnderscoreEx.Util.pipe_message(message)
              EventRegistry.unsubscribe(:nokill)
              user

            _ ->
              "Did not create user." |> UnderscoreEx.Util.pipe_message(message)
              EventRegistry.unsubscribe()
          end
      after
        10_000 ->
          "Took too long to reply." |> UnderscoreEx.Util.pipe_message(message)
          EventRegistry.unsubscribe()
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