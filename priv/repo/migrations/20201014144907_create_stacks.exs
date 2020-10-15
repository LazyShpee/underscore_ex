defmodule UnderscoreEx.Repo.Migrations.CreatStacks do
  use Ecto.Migration

  def change do
    create table(:stack_items) do
      add :user_id, :string # UserID
      add :content, :string # The item's content

      timestamps()
    end
  end
end
