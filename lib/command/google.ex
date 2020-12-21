defmodule UnderscoreEx.Command.Google do
  use UnderscoreEx.Command

  @impl true
  def parse_args(arg), do: arg

  @base_url "https://www.google.com/complete/search?cp=1&client=psy-ab&xssi=t&gs_ri=gws-wiz&hl=en-US&dpr=1"

  @impl true
  def call(%{}, arg) do
    with {:ok, {_, _, body}} <-
           :httpc.request(
             (@base_url <> "&q=" <> (:http_uri.encode(arg) |> to_string()))
             |> to_charlist()
           ),
         ")]}'\n" <> body <- body |> to_string(),
         {:ok, [parsed | _]} <- Poison.decode(body) do
      results = parsed |> Enum.map(fn [str | _] -> str |> String.replace(["<b>", "</b>"], "**") end)
      if results |> length() > 0 do
        results |> Enum.join("\n")
      else
        "No suggestion result."
      end
    else
      _ -> "Something went wrong."
    end
  end
end
