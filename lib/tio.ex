defmodule TIO do
  require Logger

  @spec init :: :ok
  def init() do
    :inets.start()
    :ets.new(:tio, [:set, :public, :named_table])

    update_info()
  end

  def disabled() do
    Mix.env() == :dev
  end

  @spec update_info :: :ok
  def update_info() do
    if disabled() do
      Logger.info("Dev env, skipping TIO.")
    else
      Logger.info("Getting TIO info...")
      vars = get_info()
      Logger.info("Getting TIO languages...")

      {:ok, {_, _, body}} =
        :httpc.request((vars["baseURL"] <> vars["languagesURL"]) |> String.to_charlist())

      langs = body |> List.to_string() |> Poison.decode!()
      Logger.info("Found #{langs |> Map.keys() |> length()} languages.")

      :ets.insert(:tio, {:vars_cache, vars})
      :ets.insert(:tio, {:langs_cache, langs})
    end

    :ok
  end

  defp to_bin(a) do
    {i, _} = Integer.parse(a, 16)
    i
  end

  defp make_token do
    :crypto.strong_rand_bytes(16) |> Base.encode16() |> String.downcase()
  end

  @base "https://tio.run/"
  @spec get_info() :: map
  def get_info() do
    {:ok, {_, _, body}} = :httpc.request(@base |> String.to_charlist())

    [_match, fe_url] =
      Regex.run(~r|<script src="([^"]+\-frontend\.js)"|, body |> List.to_string())

    {:ok, {_, _, body}} = :httpc.request((@base <> fe_url) |> String.to_charlist())
    body = List.to_string(body)

    [languages_url] = Regex.run(~r|/static[^'"]+languages.json|, body)

    vars =
      Regex.scan(~r|^var ([a-zA-Z0-9_]+)\s*=\s*"(.*?)";?|m, body)
      |> Enum.map(fn
        [_, name, <<"\\x", value::binary>>] ->
          {name, value |> String.split("\\x", trim: true) |> Enum.map(&to_bin/1) |> Enum.join("")}

        [_, name, value] ->
          {name, value}
      end)

    [{"languagesURL", languages_url}, {"baseURL", @base} | vars] |> Enum.into(%{})
  end

  defp f(data, name) do
    "F#{name}\0#{byte_size(data)}\0" <> data
  end

  defp v(data, name) do
    "V#{name}\0#{length(data)}\0" <> Enum.join(data, "\0") <> "\0"
  end

  def make_payload(code, lang, options \\ []) do
    lang = [lang]
    input = Keyword.get(options, :input, "")
    tio_options = Keyword.get(options, :tio_options, [])
    args = Keyword.get(options, :args, [])

    "" <>
      v(lang, "lang") <>
      v(tio_options, "TIO_OPTIONS") <>
      f(code, ".code.tio") <>
      f(input, ".input.tio") <>
      v(args, "args") <>
      "R"
  end

  @spec run(String.t(), String.t(), number, keyword) :: {:ok, [String.t()]}
  def run(code, lang, session_id \\ 0, options \\ []) do
    [{_, vars}] = :ets.lookup(:tio, :vars_cache)

    case :ets.lookup(:tio, session_id) do
      [] ->
        nil

      [{_, token}] ->
        :httpc.request(
          (vars["baseURL"] <> vars["quitURL"] <> "/#{token}")
          |> to_charlist()
        )
    end

    deflated_payload =
      make_payload(code, lang, options)
      |> :zlib.gzip()
      |> String.slice(10..-1)

    token = make_token()
    :ets.insert(:tio, {session_id, token})

    {:ok, {_, _, body}} =
      :httpc.request(
        :post,
        {(vars["baseURL"] <> vars["runURL"] <> "/#{token}") |> String.to_charlist(), [],
         'text/plain', deflated_payload},
        [],
        []
      )

    :ets.delete(:tio, session_id)

    raw = body |> :zlib.gunzip()

    {:ok,
     raw
     |> String.slice(16..-17)
     |> String.split(raw |> String.slice(0..15), trim: false)
     |> Enum.map(&String.trim/1)}
  end
end
