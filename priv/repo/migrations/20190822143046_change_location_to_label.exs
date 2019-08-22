defmodule UnderscoreEx.Repo.Migrations.ChangeLocationToLabel do
  use Ecto.Migration

  def change do
    rename(table(:caca_times), :location, to: :label)
  end
end
