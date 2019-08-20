defmodule UnderscoreEx.Repo.Migrations.AddDurationToCacaAndOverlapContraint do
  use Ecto.Migration

  def change do
    alter table(:caca_times) do
      remove :time
      add :t_end, :utc_datetime
      add :t_start, :utc_datetime
      add :imported, :boolean
    end
  end
end
