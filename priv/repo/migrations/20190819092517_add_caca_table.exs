defmodule UnderscoreEx.Repo.Migrations.AddCacaTable do
  use Ecto.Migration

  def change do
    create table(:caca_times) do
      add :user_id, :integer
      add :location, :string
      add :time, :utc_datetime
      add :premium_data, :map

      timestamps()
    end

    create table(:caca_users) do
      add :discord_id, :string
      add :agreed_tos, :boolean
      add :premium, :boolean

      timestamps()
    end
  end
end
