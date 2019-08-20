defmodule UnderscoreEx.Repo.Migrations.CreateEmojiNetworkTables do
  use Ecto.Migration

  def change do
    create table(:emoji_networks) do
      add :name, :string
      add :owner_id, :string
      add :description, :string
      timestamps()
    end

    create table(:emoji_guilds) do
      add :guild_id, :string
      add :network_id, :integer
      add :public, :boolean
      timestamps()
    end
    
    create table(:emoji_managers) do
      add :user_id, :string
      add :network_id, :integer
      add :acl, :integer
      timestamps()
    end
  end
end
