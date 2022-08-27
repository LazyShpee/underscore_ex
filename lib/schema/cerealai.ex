defmodule UnderscoreEx.Schema.Cerealai do
  @moduledoc false

  defmodule User do
    @moduledoc false
    use Ecto.Schema

    schema "cerealai_users" do
      field(:discord_id, UnderscoreEx.EctoType.Snowflake, default: -1)
      field(:token, :string)
      field(:user_data, :map)

      timestamps()
    end

    @charset Enum.concat([?a..?z, ?A..?Z, ?0..?9])

    def generate_token!() do
      for _ <- 1..64, into: "", do: <<Enum.random(@charset)>>
    end

    def changeset(user, params \\ %{}) do
      user
      |> Ecto.Changeset.cast(params, [:discord_id, :token, :user_data])
      |> Ecto.Changeset.validate_required([:discord_id])
      |> Ecto.Changeset.unique_constraint(:discord_id)
      |> Ecto.Changeset.unique_constraint(:token)
    end
  end
end
