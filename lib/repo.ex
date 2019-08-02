defmodule UnderscoreEx.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :underscore_ex,
    adapter: Ecto.Adapters.Postgres
end
