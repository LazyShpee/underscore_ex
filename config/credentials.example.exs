import Config

config :underscore_ex, UnderscoreEx.Repo,
  database: "underscore_ex",
  username: "underscore",
  password: ~s/super secret password/,
  hostname: "localhost",
  port: "5432"

config :underscore_ex,
  andesite_pw: ~s/uber secret password/,
  andesite_host: ~s/andes.it/,
  andesite_port: ~s/80/,
  google_api_key: ~s/my key/,
  glot_api_key: ~s/some key from glot.io/

config :nostrum,
  token: "super secret token"
