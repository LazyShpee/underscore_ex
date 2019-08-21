defmodule UnderscoreEx.Schema.SysListEntry do
  use Ecto.Schema

  schema "sys_list" do
    field(:context_id, UnderscoreEx.EctoType.Snowflake)
    field(:context_type, :string)
    field(:list_name, :string)
  end

  def changeset(entry, params \\ %{}) do
    entry
    |> Ecto.Changeset.cast(params, [:context_id, :context_type, :list_name])
    |> Ecto.Changeset.validate_required([:context_id, :context_type, :list_name])
    |> Ecto.Changeset.unique_constraint(:context_id, name: :unique_entry)
  end
end
