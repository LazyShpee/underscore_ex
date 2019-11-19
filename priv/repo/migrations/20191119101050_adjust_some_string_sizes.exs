defmodule UnderscoreEx.Repo.Migrations.AdjustSomeStirngSizes do
  use Ecto.Migration

  def change do
    alter table(:aliases) do
      modify :content, :text
    end
  end
end
