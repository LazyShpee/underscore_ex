defmodule UnderscoreEx.Command.Code do
  use UnderscoreEx.Command
  alias UnderscoreEx.Util

  @impl true
  def predicates, do: [UnderscoreEx.Predicates.syslists(["glot_whitelist"])]

  @exts %{
    "assembly" => "asm",
    "ats" => "dats",
    "bash" => "sh",
    "clojure" => "clj",
    "cobol" => "cob",
    "coffeescript" => "coffee",
    "crystal" => "cr",
    "csharp" => "cs",
    "elixir" => "ex",
    "elm" => "elm",
    "erlang" => "erl",
    "fsharp" => "fs",
    "idris" => "idr",
    "javascript" => "js",
    "julia" => "jl",
    "kotlin" => "kt",
    "mercury" => "m",
    "ocaml" => "ml",
    "perl6" => "pl",
    "python" => "py",
    "ruby" => "rb",
    "rust" => "rs",
    "typescript" => "ts"
  }
  # perl perl6 php python ruby rust scala swift typescript

  defp get_ext(lang) do
    @exts[lang] || lang
  end

  @impl true
  def parse_args(arg) do
    [~r/^```(?<lang>\w+)\n+(?<code>.+)```$/m, ~r/^(?<lang>\w+)\s+(?<code>.+)$/m]
    |> Enum.reduce_while({nil, nil}, fn elem, acc ->
      case Regex.named_captures(elem, arg) do
        nil -> {:cont, acc}
        %{"code" => code, "lang" => lang} -> {:halt, {lang, code}}
      end
    end)
  end

  @impl true
  def call(_context, {nil, nil}) do
    langs =
      Util.request(:get, "https://run.glot.io/languages")
      |> Util.get_body()
      |> Enum.map(fn %{"name" => name} -> "`#{name}`" end)
      |> Enum.join(" ")

    "Available languages: #{langs}"
  end

  @impl true
  def call(_context, {lang, code}) do
    %{} =
      reply =
      Util.request(
        :post,
        "https://run.glot.io/languages/#{lang}/latest",
        %{
          "files" => [
            %{
              "name" => "main.#{get_ext(lang)}",
              "content" => code
            }
          ]
        },
        [
          {"Authorization", "Token #{Application.get_env(:underscore_ex, :glot_api_key)}"}
        ]
      )
      |> Util.get_body()

    [
      embed: %Nostrum.Struct.Embed{
        title: "Result",
        description: String.duplicate("─", 30),
        fields:
          [
            %{
              name: "stdout",
              value: reply["stdout"]
            },
            %{
              name: "stderr",
              value: reply["stderr"]
            },
            %{
              name: "error",
              value: reply["error"]
            }
          ]
          |> Enum.reject(fn %{value: value} -> value == "" end)
          |> Enum.map(fn %{name: name, value: value} ->
            %Nostrum.Struct.Embed.Field{name: name, value: "```\n#{value |> String.slice(0..1016)}```"}
          end)
      }
    ]
  end
end
