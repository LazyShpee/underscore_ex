defmodule UnderscoreEx.Command.Eval do
  use UnderscoreEx.Command
  alias UnderscoreEx.Util

  @impl true
  def predicates,
    do: [
      &UnderscoreEx.Predicates.bot_owner/1
    ]

  @impl true
  def usage,
    do: [
      "eval [-#{flags() |> Map.keys() |> Enum.join()}] <code>"
    ]

  def description,
    do: """
    **Flags :**
    #{flags() |> Enum.map(fn {f, d} -> "  `#{f}` - #{d}" end) |> Enum.join("\n")}
    """

  defp flags,
    do: %{
      "s" => "silent",
      "r" => "no syntax highlighting",
      "R" => "no codeblock",
      "e" => "escapes for discord",
      "E" => "double escapes for discord",
      "Q" => "import database utils",
      "g" => "include guild variable",
      "c" => "include channel variable",
      "o" => "no ouput inspect"
    }

  defp find_code(content) do
    [
      ~r/^```(elixir)?\n(?<code>.+)```$/sm,
      ~r/^`(?<code>.+)`$/sm,
      ~r/^(?<code>.+)$/sm
    ]
    |> Enum.reduce_while(:not_found, fn r, acc ->
      with %{"code" => code} <- Regex.named_captures(r, content) do
        {:halt, code}
      else
        _ -> {:cont, acc}
      end
    end)
  end

  @impl true
  def call(context, _args) do
    %{"opts" => opts, "rest" => rest} =
      Regex.named_captures(~r/^\s*(-(?<opts>[a-zA-Z]+)\s+)?(?<rest>.+)/sm, context.rest)

    opts = opts |> String.split("")

    variables = [
      message: context.message,
      rest: context.rest,
      context: context,
      guild: if("g" in opts, do: Nostrum.Cache.GuildCache.get!(context.message.guild_id)),
      channel: if("c" in opts, do: Nostrum.Cache.ChannelCache.get!(context.message.channel_id))
    ]

    headers = ~s"""
    #{if "Q" in opts, do: "import Ecto.Query\nalias UnderscoreEx.Repo\nalias UnderscoreEx.Schema"}
    """

    case find_code(rest) do
      :not_found ->
        Util.usage("<some elixir code here>", context)

      code ->
        result = Util.eval(variables, headers <> "\n" <> code, (if "o" in opts, do: :raw, else: :inspect))

        if not ("s" in opts) do
          if "R" in opts do
            cond do
              "E" in opts ->
                result
                |> UnderscoreEx.Util.escape_discord()
                |> UnderscoreEx.Util.escape_discord()

              "e" in opts ->
                result
                |> UnderscoreEx.Util.escape_discord()

              true ->
                result
            end
          else
            "```#{if not ("r" in opts), do: "elixir"}\n#{result}```"
          end
        else
          :ok
        end
    end
  end
end
