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
      |> String.replace("\\\n", "")
      |> OptionParser.split()

    args =
      case args |> Enum.at(-1) |> String.match?(~r/\-$/) do
        true -> args
        false -> args |> List.insert_at(-1, "-")
      end

    result = System.cmd("magick", args)

    name =
      case UnderscoreEx.Util.File.signature(result |> elem(0)) do
        {:ok, type} -> "ouput.#{type}"
        {:error, _} -> "ouput"
      end

    case result do
      {out, 0} -> [file: %{name: name, body: out}]
      {_, _} -> "An error occurred."
    end
  end
end
