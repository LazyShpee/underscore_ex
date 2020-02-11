defmodule UnderscoreEx.Schema.Alias do
  @moduledoc false
  use Ecto.Schema

  schema "aliases" do
    # UserID
    field(:author, :string)
    # Alias name
    field(:name, :string)
    # Commands
    field(:content, :string)
    # GuildID or 0 for global
    field(:context, :string)
    # Alias description/usage
    field(:description, :string, default: "")
    # public, unlisted or private
    field(:privacy, :string, default: "private")
    # Alias type simple (bash like), advanced (argument injection etc)
    field(:type, :string, default: "simple")
    # Argument parser/splitter mode
    field(:parser, :string, default: "none")

    timestamps()
  end

  def changeset(thealias, params \\ %{}) do
    thealias
    |> Ecto.Changeset.cast(params, [
      :author,
      :name,
      :content,
      :context,
      :description,
      :privacy,
      :type,
      :parser
    ])
    |> Ecto.Changeset.validate_required([:author, :name, :content, :context])
    |> Ecto.Changeset.validate_format(:name, ~r/^[a-z0-9_~.-]+$/i)
  end
end
