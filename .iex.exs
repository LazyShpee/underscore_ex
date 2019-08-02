conn = fn -> Nostrum.Api.update_voice_state(179391900669837312, 217729331462537216) end
dconn = fn -> Nostrum.Api.update_voice_state(179391900669837312, nil) end
search = fn query ->
  {:ok, %{body: body}} = Apatite.request(:get, "/loadtracks", "", identifier: "#{query}")
  Poison.decode! body
end