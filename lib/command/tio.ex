defmodule UnderscoreEx.Command.TIO do
  use UnderscoreEx.Command

  # tio run <lang> ```<code>```
  # tio run <lang> `<code>`
  # tio run <lang> <code>

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def predicates, do: [UnderscoreEx.Predicates.syslists(["tio_users"])]

  @impl true
  def call(_context, "langs") do
    [{_, langs}] = :ets.lookup(:tio, :langs_cache)
    langs |> Map.keys() |> Enum.chunk_every(15) |> Enum.map(&Enum.join(&1, " ")) |> Enum.join("\n")
  end

  @impl true
  def call(context, <<"run ", stuff::binary>>) do
    [lang, code] = stuff |> String.split(" ", trim: true, parts: 2)
    {:ok, [res, stats]} = Elixir.TIO.run(code, lang, context.message.author.id)

    [embed: %Nostrum.Struct.Embed{
      title: "TIO Result - #{lang} - #{byte_size(code)} bytes",
      description: String.duplicate("─", 30),
      fields: [
        %Nostrum.Struct.Embed.Field{
          name: "stdout",
          value: "```\n#{res}```"
        },
        %Nostrum.Struct.Embed.Field{
          name: "misc",
          value: "```\n#{stats}```"
        },
      ]
    }]
  end
end
