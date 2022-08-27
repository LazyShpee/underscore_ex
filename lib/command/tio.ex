defmodule UnderscoreEx.Command.TIO do
  use UnderscoreEx.Command
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Field
  # tio run <lang> ```<code>```
  # tio run <lang> `<code>`
  # tio run <lang> <code>

  @impl true
  def parse_args(arg), do: arg |> String.split(" ", trim: true, parts: 2)

  @impl true
  def predicates, do: [UnderscoreEx.Predicates.syslists(["tio_users"]), UnderscoreEx.Predicates.env(:dev, :blacklist)]

  def usage,
    do: [
      "run <language> <code>",
      "lang [query]",
      "lang random"
    ]

  # @impl true
  # def call(_context, ["langs"]) do
  #   [{_, langs}] = :ets.lookup(:tio, :langs_cache)

  #   langs
  #   |> Map.keys()
  #   |> Enum.chunk_every(15)
  #   |> Enum.map(&Enum.join(&1, " "))
  #   |> Enum.join("\n")
  # end

  @impl true
  def call(_context, ["lang", "random"]) do
    [{_, langs}] = :ets.lookup(:tio, :langs_cache)

    langs
    |> Map.keys()
    |> Enum.shuffle()
    |> Enum.take(10)
    |> Enum.join(", ")
  end

  @impl true
  def call(_context, ["lang"]) do
    [{_, langs}] = :ets.lookup(:tio, :langs_cache)

    "I know #{langs |> Map.keys() |> length()} languages."
  end

  @impl true
  def call(_context, ["lang", query]) do
    [{_, langs}] = :ets.lookup(:tio, :langs_cache)
    query = String.downcase(query)

    langs
    |> Map.keys()
    |> Enum.map(&{&1, String.jaro_distance(&1, query)})
    |> Enum.sort(fn {_, d1}, {_, d2} -> d1 > d2 end)
    |> Enum.take(10)
    |> case do
      [{lang, 1.0} | other_langs] ->
        info = langs[lang]

        hello =
          info["tests"]["helloWorld"]["request"]
          |> case do
            [%{"payload" => %{".code.tio" => code}} | _] when byte_size(code) <= 1024 - 7 ->
              "```\n#{code}```"

            _ ->
              "*Could not find an example*"
          end

        [
          embed: %Embed{
            title: info["name"],
            url: info["link"],
            description: "[Try It Online](https://tio.run/##{query})",
            color: 12_757_499,
            fields: [
              %Field{
                name: "Categories",
                value: info["categories"] |> Enum.join(" "),
                inline: true
              },
              %Field{
                name: "Encoding",
                value: info["encoding"],
                inline: true
              },
              %Field{
                name: "Hello World !",
                value: hello
              },
              %Field{
                name: "Others matches",
                value: other_langs |> Enum.map(&elem(&1, 0)) |> Enum.join(", ")
              }
            ]
          }
        ]

      langs ->
        langs |> Enum.map(&elem(&1, 0)) |> Enum.join(", ")
    end
  end

  @impl true
  def call(context, ["run", stuff]) do
    [lang, code] = stuff |> String.split([" ", "\n"], trim: true, parts: 2)

    with {:ok, [stdout, misc]} <- Elixir.TIO.run(code, lang, context.message.author.id) do
      {stderr, stats} = misc |> String.split("\n") |> Enum.split(-5)

      [
        embed: %Embed{
          title: "TIO Result - #{lang} - #{byte_size(code)} bytes",
          description: String.duplicate("─", 30),
          fields:
            [
              %Field{
                name: "stdout",
                value: stdout |> String.trim()
              },
              %Field{
                name: "stderr",
                value: stderr |> Enum.join("\n") |> String.trim()
              },
              %Field{
                name: "stats",
                value: stats |> Enum.join("\n") |> String.trim()
              }
            ]
            |> Enum.reject(fn %Field{value: v} -> byte_size(v) === 0 end)
            |> Enum.map(fn %Field{value: v} = field ->
              %Field{field | value: "```\n#{v |> String.slice(0..1016)}```"}
            end)
        }
      ]
    else
      {:ok, [stuff]} -> "Error: #{stuff}"
    end
  end

  def call(context, _) do
    UnderscoreEx.Command.Help.call(context, "tio")
  end
end
