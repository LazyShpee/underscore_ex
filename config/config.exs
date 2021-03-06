import Config

config :nostrum,
  num_shards: :auto,
  gateway_intents: :all

config :porcelain, driver: Porcelain.Driver.Basic

config :logger, :console, metadata: [:shard]

config :postgrex, :json_library, Poison

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :underscore_ex, ecto_repos: [UnderscoreEx.Repo]

import_config "credentials.exs"
import_config "#{Mix.env()}.exs"
