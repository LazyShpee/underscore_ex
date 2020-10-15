defmodule UnderscoreEx.Command.Text do
  use UnderscoreEx.Command

  defmodule Formatter do
    def scramble(text) do
      text
      |> String.split()
      |> Enum.shuffle()
      |> Enum.join(" ")
    end
  end

  def format(text) do
    ~r/\{(\S+)\s+([^}]+)\}/
    |> Regex.replace(text, fn all, action, text ->
      case action do
        "scramble" -> Formatter.scramble(text)
        _ -> all
      end
    end)
  end

  def foo do
    with true <- true,
         false <- false, do: false

  end

  @impl true
  def predicates,
    do: [
      UnderscoreEx.Predicates.syslists(["text"])
    ]

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def call(_context, args) do
    format(args)
  end
end
