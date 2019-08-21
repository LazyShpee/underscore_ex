defmodule UnderscoreEx.Command.Su do
  use UnderscoreEx.Command

  @impl true
  def predicates, do: [&UnderscoreEx.Predicates.bot_owner/1]

  @impl true
  def parse_args(arg), do: arg |> String.split(" ", parts: 2, trim: true)

  @impl true
  def call(%{message: message, prefix: prefix}, [user, command]) do
    content = case command do
      <<"raw:", rest::binary>> -> rest
      command -> "#{prefix}#{command}"
    end

    {:ok, id} = UnderscoreEx.Util.resolve_user_id(user, message.guild_id)

    tmp = message
    |> Map.from_struct()
    |> update_in([:author], &Map.from_struct/1)
    |> update_in([:author, :id], fn _ -> id end)
    |> update_in([:author], &struct!(%Nostrum.Struct.User{}, &1))
    |> update_in([:content], fn _ -> "#{content}" end)

    UnderscoreEx.Core.run(struct!(%Nostrum.Struct.Message{}, tmp))
    :ok
  end
end
