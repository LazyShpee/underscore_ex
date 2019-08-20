defmodule UnderscoreEx.Repo.Migrations.CreateCacheVideoTimestamps do
  use Ecto.Migration

  def change do
    create table(:cache_video_timestamps) do
      add :source, :string
      add :source_type, :string
      add :timestamps, {:array, {:array, :string}}

      timestamps()
    end
  end
end
