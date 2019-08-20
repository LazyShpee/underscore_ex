import Config

config :nostrum,
  num_shards: :auto

config :logger, :console, metadata: [:shard]

config :postgrex, :json_library, Poison

import_config "credentials.exs"
import_config "#{Mix.env()}.exs"
