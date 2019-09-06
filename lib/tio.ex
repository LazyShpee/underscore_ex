defmodule TIO do
  require Logger

  def init() do
    :ets.new(:tio, [:set, :public, :named_table])

    Logger.info("Getting TIO info...")
    vars = get_info()
    Logger.info("Getting TIO languages...")
    {:ok, %{body: body}} = HTTPoison.get(vars["baseURL"] <> vars["languagesURL"])
    langs = body |> Poison.decode!()
    Logger.info("Found #{langs |> Map.keys() |> length()} languages.")

    :ets.insert(:tio, {:vars_cache, vars})
    :ets.insert(:tio, {:langs_cache, langs})
  end

  defp to_bin(a) do
    {i, _} = Integer.parse(a, 16)
    <<i>>
  end

  defp make_token do
    :crypto.strong_rand_bytes(16) |> Base.encode16() |> String.downcase()
  end

  @base "https://tio.run/"
  def get_info do
    {:ok, %{body: body}} = HTTPoison.get(@base)
    [_match, fe_url] = Regex.run(~r|<script src="([^"]+\-frontend\.js)"|, body)
    {:ok, %{body: body}} = HTTPoison.get(@base <> fe_url)

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

  @doc """
  V<name><<0>><number of elements><<0>><element 1><<0>>[...]<element n><<0>>
  F<name><<0>><number of characters><<0>><file data>
  R

  V lang -> language
  V TIO_OPTIONS -> command line options
  F .code.tio -> code contents
  F .input.tio -> stdin
  V args -> script arguments
  R
  |> deflate


  https://github.com/TryItOnline/tryitonline/blob/3a6705314348a4e47d319c38025e11d845e4355c/usr/share/tio.run/frontend.js#L162
  response |> slice(10)
  |> inflate

  """
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

  def run(code, lang, session_id \\ 0, options \\ []) do
    [{_, vars}] = :ets.lookup(:tio, :vars_cache)

    case :ets.lookup(:tio, session_id) do
      [] ->
        nil

      [{_, token}] ->
        HTTPoison.get(vars["baseURL"] <> vars["quitURL"] <> "/#{token}")
    end
    deflated_payload = make_payload(code, lang, options) |> :zlib.gzip() |> String.slice(10..-1)
    token = make_token()
    :ets.insert(:tio, {session_id, token})

    {:ok, %{body: body}} =
      HTTPoison.post(vars["baseURL"] <> vars["runURL"] <> "/#{token}", deflated_payload)

    :ets.delete(:tio, session_id)

    raw = body |> :zlib.gunzip()

    {:ok,
     raw
     |> String.slice(16..-17)
     |> String.split(raw |> String.slice(0..15), trim: false)
     |> Enum.map(&String.trim/1)}
  end
end
