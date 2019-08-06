defmodule UnderscoreEx.Command.Test do
  use UnderscoreEx.Command

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def predicates, do: [&UnderscoreEx.Predicates.bot_owner/1]

  @impl true
  def call(%{self: {type, _, depth}}, _args) do
    """
    I'm a *`:#{type}`*.
    I'm at depth **#{depth}**.
    """
  end
end