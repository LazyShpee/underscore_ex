defmodule UnderscoreEx.Schema.CachedVideoTimestamps do
  @moduledoc false
  use Ecto.Schema

  schema "cache_video_timestamps" do
    field(:source, :string)
    field(:source_type, :string)
    field(:timestamps, {:array, {:array, :string}})

    timestamps()
  end

  def changeset(cached_item, params \\ %{}) do
    cached_item
    |> Ecto.Changeset.cast(params, [:source, :source_type, :timestamps])
    |> Ecto.Changeset.validate_required([:source, :source_type, :timestamps])
  end
end
