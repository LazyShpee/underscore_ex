defmodule UnderscoreEx.Repo.Migrations.AddCacaTimesFields do
  use Ecto.Migration

  def change do
    alter table(:caca_times) do
      add :t_upload, :utc_datetime
      add :partial, :boolean
    end
  end
end
