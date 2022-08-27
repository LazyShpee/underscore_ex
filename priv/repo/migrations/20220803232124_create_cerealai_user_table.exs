defmodule UnderscoreEx.Repo.Migrations.CreateCerealaiUserTable do
  use Ecto.Migration

  def change do
    create table(:cerealai_users) do
      add :discord_id, :string # Discord user snowflake as string
      add :token, :string # The user's token
      add :user_data, :map, default: "{}" # Some user data to share accross clients, I guess
      timestamps()
    end

    create unique_index(:cerealai_users, [:discord_id])
    create unique_index(:cerealai_users, [:token])
  end
end
