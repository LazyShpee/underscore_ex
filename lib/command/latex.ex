defmodule UnderscoreEx.Command.Latex do
  use UnderscoreEx.Command
  alias UnderscoreEx.Util

  @impl true
  def parse_args(arg), do: arg

  # Todo: move to https://quicklatex.com/

  @impl true
  def call(%{message: message}, content) do
    data = %{
      auth: %{
        user: "guest",
        password: "guest"
      },
      latex: content,
      resolution: 300,
      color: "ffffff"
    }

    embed =
      with {:ok, body} <- data |> Poison.encode(),
           {:ok, %{body: body}} <- HTTPoison.post("http://latex2png.com/api/convert", body),
           {:ok, body} <- Poison.decode(body) do
        case body["result-code"] do
          0 ->
            %Nostrum.Struct.Embed{
              color: 123_456,
              image: %Nostrum.Struct.Embed.Image{
                url: "http://latex2png.com#{body["url"]}"
              },
              title: "Result"
            }

          _ ->
            %Nostrum.Struct.Embed{
              color: 13_577_244,
              title: "Error",
              description: body["result-message"] |> Util.unescape_discord()
            }
        end
      else
        e -> IO.inspect(e)
      end

    [embed: embed]
    |> Util.pipe_message(message)
  end
end
