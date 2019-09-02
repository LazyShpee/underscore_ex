defmodule UnderscoreEx.Command.CFG do
  use UnderscoreEx.Command

  @impl true
  def predicates, do: [&UnderscoreEx.Predicates.bot_owner/1]

  @impl true
  defdelegate parse_args(args), to: OptionParser, as: :split

  @impl true
  def call(_context, [key, value]) do
    import Exredis.Api

    with {:ok, client} <- Exredis.start_link(),
         :ok <- client |> set("underscoreex:#{key}", value),
         Exredis.stop(client) do
      "Set `#{key}` to `#{value}`."
    end
  end

  @impl true
  def call(_context, [key]) do
    import Exredis.Api

    with {:ok, client} <- Exredis.start_link(),
         value <- client |> get("underscoreex:#{key}"),
         Exredis.stop(client) do
      case value do
        :undefined ->
          "#{key} is undefined."

        value ->
          "`#{key}` is set to `#{value}`."
      end
    end
  end
end
