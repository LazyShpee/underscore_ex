defmodule UnderscoreEx.Schema.Caca do
  @moduledoc false

  defmodule Time do
    @moduledoc false
    use Ecto.Schema

    schema "caca_times" do
      field(:user_id, :integer)
      field(:label, :string, default: "")
      field(:t_start, :utc_datetime)
      field(:t_end, :utc_datetime)
      field(:imported, :boolean, default: false)
      field(:partial, :boolean, default: false)
      field(:premium_data, :map, default: %{})
      field(:t_upload, :utc_datetime)

      timestamps()
    end

    def changeset(caca, params \\ %{}) do
      caca
      |> Ecto.Changeset.cast(params, [
        :user_id,
        :label,
        :t_start,
        :t_end,
        :premium_data,
        :imported,
        :t_upload,
        :partial,
      ])
      |> Ecto.Changeset.validate_required([:user_id, :t_start, :t_end])
      |> Ecto.Changeset.check_constraint(:start, name: :start_before_end)
      |> Ecto.Changeset.exclusion_constraint(:user_id, name: :no_overlapping_caca)
    end
  end

  defmodule User do
    @moduledoc false
    use Ecto.Schema

    schema "caca_users" do
      field(:discord_id, UnderscoreEx.EctoType.Snowflake, default: -1)
      field(:agreed_tos, :boolean, default: false)
      field(:premium, :boolean, default: false)

      timestamps()
    end

    def changeset(user, params \\ %{}) do
      user
      |> Ecto.Changeset.cast(params, [:discord_id, :agreed_tos, :premium])
    end
  end
end
