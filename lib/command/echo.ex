defmodule UnderscoreEx.Command.Echo do
  use UnderscoreEx.Command

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def predicates, do: [UnderscoreEx.Predicates.perms([:manage_messages], :any)]

  @impl true
  def call(_context, "-E " <> args) do
    args
    |> UnderscoreEx.Util.escape_discord()
    |> UnderscoreEx.Util.escape_discord()
  end

  @impl true
  def call(_context, "-e " <> args) do
    args
    |> UnderscoreEx.Util.escape_discord()
  end

  @impl true
  def call(_context, "-U " <> args) do
    args
    |> UnderscoreEx.Util.unescape_discord()
    |> UnderscoreEx.Util.unescape_discord()
  end

  @impl true
  def call(_context, "-u " <> args) do
    args
    |> UnderscoreEx.Util.unescape_discord()
  end

  @impl true
  def call(_context, args) do
    args
  end
end
