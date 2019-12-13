defmodule UnderscoreEx.Repo.Migrations.AdjustSomeStringSizes do
  use Ecto.Migration

  def change do
    alter table(:aliases) do
      modify :content, :text
    end
  end
end
