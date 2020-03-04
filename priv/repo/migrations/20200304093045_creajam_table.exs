defmodule UnderscoreEx.Repo.Migrations.CreajamTable do
  use Ecto.Migration

  def change do
    create table(:creajam) do
      add :theme_message_id, :string
      add :theme_channel_id, :string
      add :submit_channel_id, :string
      add :theme, :string
      add :participation_count, :integer
      add :number, :integer
      add :is_test, :boolean

      timestamps()
    end
  end
end
