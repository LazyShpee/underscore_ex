defmodule UnderscoreEx.Command.Math do
  use UnderscoreEx.Command

  @impl true
  def parse_args(arg), do: arg

  @impl true
  def call(context, expression) do
    with {:ok, expr} <- Abacus.format(expression),
         {:ok, res} <-
           Abacus.eval(expression, %{
             "me" => context.message.author.id
           }) do
      [
        embed: %Nostrum.Struct.Embed{
          title: "Abacus",
          description: """
          #{String.duplicate("─", 30)}
          ```
          #{expr}
          ```
          """,
          fields: [
            %Nostrum.Struct.Embed.Field{
              name: "Result",
              value: "```= #{res}```"
            }
          ]
        }
      ]
    else
      {:error, {line, :math_term_parser, [reason, stuff]}} ->
        {:halt, "Line #{line}: #{reason}`#{stuff}`"}

      e ->
        {:halt, "Error: `#{inspect(e)}`"}
    end
  end
end
