import Config

config :nostrum,
  num_shards: :auto

config :logger, :console, metadata: [:shard]

import_config "credentials.exs"
import_config "#{Mix.env()}.exs"
