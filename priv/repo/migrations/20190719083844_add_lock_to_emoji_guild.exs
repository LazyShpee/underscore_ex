defmodule UnderscoreEx.Repo.Migrations.AddLockToEmojiGuild do
  use Ecto.Migration

  def change do
    alter table(:emoji_guilds) do
      add :locked, :boolean
    end
  end
end
