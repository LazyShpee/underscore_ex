defmodule UnderscoreEx.Repo.Migrations.CreateAliases do
  use Ecto.Migration

  def change do
    create table(:aliases) do
      add :author, :string # UserID
      add :name, :string # Alias name
      add :content, :string # Commands
      add :context, :string # GuildID or 0 for global
      add :description, :string # Alias description/usage
      add :privacy, :string # public, unlisted or private
      add :type, :string # Alias type simple (bash like), advanced (argument injection etc)
      add :parser, :string # Argument parser/splitter mode

      timestamps()
    end
  end
end
