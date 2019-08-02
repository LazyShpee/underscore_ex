defmodule Apatite do
  def https(resource) do
    "https://#{Application.get_env(:underscore_ex, :andesite_host)}#{resource}"
  end

  def request(method, resource, payload, params \\ [])

  def request(method, resource, %{} = payload, params) do
    request(method, resource, Poison.encode!(payload), params)
  end

  def request(method, resource, payload, params) do
    HTTPoison.request(
      method,
      https(resource),
      payload,
      [
        {"Authorization", Application.get_env(:underscore_ex, :andesite_pw)},
        {"User-Id", "#{Nostrum.Cache.Me.get().id}"}
      ],
      params: params
    )
  end

  def play(track, guild_id) do
    request(:post, "/player/#{guild_id}/play", %{
      track: track,
      noReplace: false
    })
  end

  def voice_server_update(session_id, event) do
    request(:post, "/player/voice-server-update", %{
      sessionId: session_id,
      guildId: event.guild_id |> Integer.to_string(),
      event: %{
        endpoint: event.endpoint,
        guildId: "#{event.guild_id}",
        token: event.token
      }
    })
  end
end
