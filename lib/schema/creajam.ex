defmodule UnderscoreEx.Schema.Creajam do
  @moduledoc false
  use Ecto.Schema

  schema "creajam" do
    field(:theme_message_id, UnderscoreEx.EctoType.Snowflake, default: -1)
    field(:theme_channel_id, UnderscoreEx.EctoType.Snowflake, default: -1)
    field(:submit_channel_id, UnderscoreEx.EctoType.Snowflake, default: -1)
    field(:theme, :string)
    field(:participation_count, :integer, default: 0)
    field(:number, :integer, default: 1)
    field(:is_test, :boolean, default: false)
    field(:ended, :boolean, default: false)

    timestamps()
  end

  def changeset(entry, params \\ %{}) do
    entry
    |> Ecto.Changeset.cast(params, [
      :theme_message_id,
      :theme_channel_id,
      :submit_channel_id,
      :theme,
      :participation_count,
      :number,
      :is_test,
      :ended
    ])
  end
end
