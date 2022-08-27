import Config

config :nostrum,
  num_shards: :auto,
  gateway_intents: :all

# config :porcelain, driver: Porcelain.Driver.Basic

config :logger, :console, metadata: [:shard]

config :postgrex, :json_library, Jason

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :underscore_ex, ecto_repos: [UnderscoreEx.Repo]

import_config "credentials.exs"
import_config "#{Mix.env()}.exs"

config :nostrum,
  gateway_intents: [
    :message_content,
    :guilds,
    :guild_members,
    :guild_bans,
    :guild_emojis,
    :guild_webhooks,
    :guild_invites,
    :guild_voice_states,
    :guild_messages,
    :guild_message_reactions,
    :direct_messages,
    :direct_message_reactions

    # other gateway intents
  ]
