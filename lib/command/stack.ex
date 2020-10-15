defmodule UnderscoreEx.Command.Stack do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.StackItem
  alias UnderscoreEx.Repo

  @impl true
  def predicates, do: [&UnderscoreEx.Predicates.bot_owner/1]

  @impl true
  def parse_args(arg), do: arg |> String.split(" ", parts: 2) |> Enum.map(&String.trim/1) |> List.to_tuple()

  @impl true
  def description, do: "Here be dragons."

  @impl true # Clear
  def call(_ctx, {op}) when op in ["clear"] do
    "Clear stack"
  end

  @impl true # Add
  def call(_ctx, {op, arg}) when op in ["+", "push"] do
    "Add #{arg} to stack"
  end

  @impl true # Remove
  def call(_ctx, {op, arg}) when op in ["-", "pop"] do
    "Remove #{arg} to stack"
  end

  @impl true # Show
  def call(_ctx, {op}) when op in ["?", "show"] do
    "Show stack"
  end

  @impl true
  def call(_, _), do: "Eh?"

end
