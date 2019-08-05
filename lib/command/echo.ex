defmodule UnderscoreEx.Command.Echo do
  use UnderscoreEx.Command

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def predicates, do: [&UnderscoreEx.Predicates.bot_owner/1]

  @impl true
  def call(_context, args) do
    args
  end
end
