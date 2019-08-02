defmodule UnderscoreEx.Command.Eval do
  use UnderscoreEx.Command
  alias UnderscoreEx.Util

  @impl true
  def predicates,
    do: [
      &UnderscoreEx.Predicates.bot_owner/1
    ]

  defp find_code(content) do
    [
      ~r/^```(elixir)?\n(?<code>.+)```$/m,
      ~r/^`(?<code>.+)`$/m,
      ~r/^(?<code>.+)$/m
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
    case find_code(context.rest) do
      :not_found ->
        Util.usage("<some elixir code here>", context)

      code ->
        "```elixir\n#{Util.eval([message: context.message, rest: context.rest], code)}```"
    end
  end
end
