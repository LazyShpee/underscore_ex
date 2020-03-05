defmodule UnderscoreEx.Repo.Migrations.AddCreajamEndedField do
  use Ecto.Migration

  def change do
    alter table(:creajam) do
      add :ended, :boolean
    end
  end
end
