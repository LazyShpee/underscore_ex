defmodule UnderscoreEx.Command.Private.RCon do
  use UnderscoreEx.Command

  @impl true
  def predicates,
    do: [
      UnderscoreEx.Predicates.guild([625_270_974_065_016_832]),
      UnderscoreEx.Predicates.user([87_574_389_666_611_200, 88_608_197_891_346_432])
    ]

  @impl true
  def parse_args(args), do: args

  def exec(cmd) do
    with {:ok, conn} <-
           RCON.Client.connect(
             Application.get_env(:underscore_ex, :mc_rcon_address),
             Application.get_env(:underscore_ex, :mc_rcon_port)
           ),
         {:ok, conn, true} <-
           RCON.Client.authenticate(conn, Application.get_env(:underscore_ex, :mc_rcon_pw)),
         {:ok, conn, result} <- RCON.Client.exec(conn, cmd) do
      conn |> elem(0) |> Socket.close()
      result
    else
      {:error, _e} ->
        {:error, "Could not connect."}

      {:error, conn, false} ->
        conn |> elem(0) |> Socket.close()
        {:error, "Could not connect."}
    end
  end

  @impl true
  def call(_context, cmd) do
    exec(cmd)
  end

  def handle_message(%{channel_id: channel_id, content: content, author: %{username: username}}) do
    content =
      content
      |> String.split("", trim: true)
      |> Enum.reject(&(byte_size(&1) > 1))
      |> Enum.join("")

    content =
      ~r/<(#|@|:[^:]+:)!?(\d+)>/
      |> Regex.replace(content, fn
        _, "#", id ->
          case Nostrum.Cache.ChannelCache.get(id |> String.to_integer()) do
            {:ok, %{name: name}} -> "##{name}"
            _ -> "#???"
          end

        _, "@", id ->
          case Nostrum.Cache.UserCache.get(id |> String.to_integer()) do
            {:ok, %{username: username}} -> "@#{username}"
            _ -> "@???"
          end

        _, emoji, _ ->
          emoji
      end)

    if channel_id == Application.get_env(:underscore_ex, :mc_chat_channel) and
         byte_size(content) > 0 do
      {:ok, json} = Poison.encode([%{text: "{#{username}} #{content}"}])
      exec("tellraw @a #{json}")
    end

    {:ok}
  end
end
