defmodule UnderscoreEx.Command.IM do
  use UnderscoreEx.Command

  @impl true
  def predicates, do: [&UnderscoreEx.Predicates.bot_owner/1]

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def description, do: "Here be dragons."

  @impl true
  def call(%{message: %{attachments: attachments}}, arg) do
    args =
      Regex.replace(~r/<(.+?)>/, arg, fn
        _, <<"http", _::binary>> = url ->
          url

        c, n ->
          with {n, _} <- Integer.parse(n),
               %{url: url} <- Enum.at(attachments, n) do
            url
          else
            _ -> c
          end
      end)
      |> OptionParser.split()
      |> IO.inspect()

    type = Enum.at(args, -1)

    case System.cmd("magick", args |> List.replace_at(-1, "#{type}:-")) do
      {out, 0} -> [file: %{name: "output.#{type}", body: out}]
      {_, _} -> "An error occurred."
    end
  end
end
