defmodule UnderscoreEx.Repo.Migrations.AddUniqueNameIdToEmojiTables do
  use Ecto.Migration

  def change do
    alter table(:emoji_networks) do
      add :name_id, :string
    end
    create unique_index(:emoji_networks, [:name_id])

    alter table(:emoji_guilds) do
      add :name_id, :string
    end
    create unique_index(:emoji_guilds, [:name_id, :network_id])
    create unique_index(:emoji_guilds, [:guild_id])
    create unique_index(:emoji_managers, [:user_id, :network_id])
  end
end
