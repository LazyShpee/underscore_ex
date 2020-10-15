defmodule UnderscoreEx.Schema.StackItem do
  @moduledoc false
  use Ecto.Schema

  schema "stack_items" do
    field(:user_id, UnderscoreEx.EctoType.Snowflake)
    field(:content, :string)

    timestamps()
  end

  def changeset(item, params \\ %{}) do
    item
    |> Ecto.Changeset.cast(params, [:user_id, :content])
    |> Ecto.Changeset.validate_required([:user_id])
  end
end
