defmodule UnderscoreEx.Command.Caca.Import do
  use UnderscoreEx.Command
  alias UnderscoreEx.Command.Caca

  @impl true
  def parse_args(arg), do: arg |> String.split("\n", trim: true)

  @impl true
  defdelegate predicates, to: Caca

  @impl true
  def call(context, lines) do
    with _user <- Caca.get_user(context) do
      {_multi, _rejected} =
        lines
        |> Enum.reduce({Ecto.Multi.new(), []}, fn line, {multi, rejected} ->
          destructure([date, _location], line |> String.split(" ", trim: true, parts: 2))

          with {:ok, _date} <- Timex.parse!(date, "{YYYY}{0M}{0D}{h24}{m}") do
            # {multi |> Multi.insert(), rejected}
          else
            _ -> {multi, rejected ++ line}
          end
        end)
    end
  end
end
