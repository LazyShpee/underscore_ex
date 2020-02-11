defmodule UnderscoreEx.Command.Emoji.Prepare do
  use UnderscoreEx.Command

  @impl true
  def predicates, do: [UnderscoreEx.Predicates.syslists(["emoji_prepare_nee"])]

  @impl true
  def usage,
    do: [
      "<target path> <emoji name> <square image url>"
    ]

  @impl true
  def call(%{prefix: prefix, message: %{channel_id: channel_id}}, [
        target,
        name,
        "http" <> _ = url
      ]) do
    input = "( -background none -density 600 #{url} -resize 128x128 )"

    len = name |> String.length()

    names = [
      name |> String.slice(0..(ceil(len / 2) - 1)),
      name |> String.slice(ceil(len / 2) - 1, 1) |> String.duplicate(10),
      name |> String.slice(ceil(len / 2)..-1)
    ]

    batch =
      [
        ~w{ #{input} -crop 50x100% -gravity east -background none -extent 128x128 png:- },
        ~w{ ( #{input} -crop 1x100%+63+0 ) -resize 128x128! png:- },
        ~w{ #{input} -crop 50x100+64+0% -gravity west -background none -extent 128x128 png:- }
      ]
      |> Enum.map(fn args ->
        {data, 0} = System.cmd("magick", args)
        data
      end)
      |> Enum.map(fn data ->
        Nostrum.Api.create_message(channel_id, file: %{body: data, name: "output.png"})
      end)
      |> Enum.zip(names)
      |> Enum.map(fn {{:ok, %{attachments: [%{url: url} | _]}}, name} ->
        "emoji add #{target}/#{name} <" <> url <> ">"
      end)
      |> Enum.join(" ;; ")

    prefix <> batch
  end
end
