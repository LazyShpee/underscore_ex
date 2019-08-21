defmodule UnderscoreEx.Repo.Migrations.CreateSystemList do
  use Ecto.Migration

  def change do
    create table(:sys_list) do
      add :context_id, :string
      add :context_type, :string
      add :list_name, :string
    end

    create unique_index(:sys_list, [:list_name, :context_id, :context_type], name: :unique_entry)
  end
end
