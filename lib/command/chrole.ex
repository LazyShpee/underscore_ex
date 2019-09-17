defmodule UnderscoreEx.Command.ChRole do
  use UnderscoreEx.Command

  # __start_chrole
  # __stop_chrole

  @impl true
  def usage, do: [
    "",
    "(<+|-><role name>)+"
  ]

  @impl true
  def predicates, do: [UnderscoreEx.Predicates.context(:guild)]

  @impl true
  def parse_args(arg), do: OptionParser.split(arg)

  defp resolve_op(<<op::binary-size(1), role::binary>>, roles) when op in ["+", "-"] do
    role = String.downcase(role)

    roles
    |> Enum.map(fn {id, %{name: name}} ->
      {id, String.jaro_distance(String.downcase(name), role)}
    end)
    |> Enum.sort(fn {_, a}, {_, b} -> a > b end)
    |> hd
    |> Tuple.insert_at(0, op)
  end

  @impl true
  def call(context, ops) do
    roles =
      Nostrum.Cache.GuildCache.get!(context.message.guild_id).roles
      |> Enum.sort(fn {_, %{position: p1}}, {_, %{position: p2}} -> p1 > p2 end)
      |> Enum.drop_while(fn {_, %{name: name}} -> name != "__chrole_start" end)
      |> Enum.take_while(fn {_, %{name: name}} -> name != "__chrole_stop" end)
      |> Enum.drop(1)

    case length(roles) do
      0 ->
        "No chroles setup for this guild."

      n when ops == [] ->
        "#{n} chrole(s): " <> (Enum.map(roles, fn {_, %{name: name}} -> name end)
        |> Enum.join(", "))

      _ ->
        ops
        |> Enum.map(&resolve_op(&1, roles))
        |> Enum.reject(fn {_, _, d} -> d < 0.7 end)
        |> Enum.each(fn
          {"+", id, _} ->
            Nostrum.Api.add_guild_member_role(
              context.message.guild_id,
              context.message.author.id,
              id,
              "CHROLE"
            )

          {"-", id, _} ->
            Nostrum.Api.remove_guild_member_role(
              context.message.guild_id,
              context.message.author.id,
              id,
              "CHROLE"
            )
        end)

        "Done, ig."
    end
  end
end
