defmodule UnderscoreEx.Command.Suggest do
  use UnderscoreEx.Command

  @impl true
  def usage(), do: ["(google|bing) <query>"]

  @impl true
  def parse_args(arg),
    do:
      [_, _]
      |> destructure(arg |> String.split(" ", parts: 2, trim: true))
      |> Enum.map(&(&1 || ""))
      |> List.to_tuple()

  @impl true
  def call(%{}, {"google", arg}) do
    with {:ok, {_, _, body}} <-
           :httpc.request(
             ("https://www.google.com/complete/search?cp=1&client=psy-ab&xssi=t&gs_ri=gws-wiz&hl=en-us&dpr=1&q=" <>
                (:http_uri.encode(arg) |> to_string()))
             |> to_charlist()
           ),
         ")]}'\n" <> body <- body |> to_string(),
         {:ok, [parsed | _]} <- Poison.decode(body) do
      results =
        parsed |> Enum.map(fn [str | _] -> str |> String.replace(["<b>", "</b>"], "**") end)

      if results |> length() > 0 do
        results |> Enum.join("\n")
      else
        "No suggestion result."
      end
    else
      _ -> "Something went wrong."
    end
  end

  @impl true
  def call(%{}, {"bing", arg}) do
    with {:ok, {_, _, body}} <-
           :httpc.request(
             ("https://www.bing.com/AS/Suggestions?mkt=en-us&cvid=1&qry=" <>
                (:http_uri.encode(arg) |> to_string()))
             |> to_charlist()
           ),
         body <- body |> to_string() do
      results =
        ~r/<span[^>]+?>(.*?)<\/span>/ |> Regex.scan(body) |> Enum.map(fn [_, m] -> m |> String.replace(["<strong>", "</strong>"], "**") end)

      if results |> length() > 0 do
        results |> Enum.join("\n")
      else
        "No suggestion result."
      end
    else
      _ -> "Something went wrong."
    end
  end

  @impl true
  def call(%{}, _) do
    :noop
  end
end
