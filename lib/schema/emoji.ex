defmodule UnderscoreEx.Schema.Emoji do
  @moduledoc false
  defmodule Guild do
    @moduledoc false
    use Ecto.Schema

    schema "emoji_guilds" do
      field(:guild_id, :string)
      field(:name_id, :string)
      field(:locked, :boolean, default: false)
      field(:public, :boolean, default: false)
      field(:network_id, :integer)
      timestamps()
    end

    @yes_str ~W(yes y true)
    @no_str ~W(no n false)
    @yesno_str @yes_str ++ @no_str
    defp convert_params(params) do
      locked = params[:locked] || "" |> String.downcase()
      public = params[:public] || "" |> String.downcase()

      params =
        if locked in @yesno_str do
          %{params | locked: locked in @yes_str}
        else
          params
        end

      if public in @yesno_str do
        %{params | public: public in @yes_str}
      else
        params
      end
    end

    def changeset(guild, params \\ %{}) do
      guild
      |> Ecto.Changeset.cast(params |> convert_params, [
        :guild_id,
        :network_id,
        :public,
        :name_id,
        :locked
      ])
      |> Ecto.Changeset.validate_required([:guild_id, :network_id, :name_id, :public, :locked])
      |> Ecto.Changeset.validate_format(:name_id, ~r/^[a-z0-9_-]+$/i)
      |> Ecto.Changeset.unique_constraint(:guild_id)
      |> Ecto.Changeset.unique_constraint(:name_id_network_id)
    end
  end

  defmodule Manager do
    @moduledoc false
    use Ecto.Schema

    schema "emoji_managers" do
      field(:user_id, :string)
      field(:network_id, :integer)
      field(:acl, :integer, default: 0b1111)
      timestamps()
    end

    def changeset(manager, params \\ %{}) do
      manager
      |> Ecto.Changeset.cast(params, [:user_id, :network_id, :acl])
      |> Ecto.Changeset.validate_required([:user_id, :network_id, :acl])
      |> Ecto.Changeset.unique_constraint(:user_id_network_id)
    end
  end

  defmodule Network do
    @moduledoc false
    use Ecto.Schema

    schema "emoji_networks" do
      field(:name, :string)
      field(:name_id, :string)
      field(:owner_id, :string)
      field(:description, :string, default: "")
      has_many(:guilds, Guild)
      has_many(:managers, Manager)
      timestamps()
    end

    def changeset(network, params \\ %{}) do
      network
      |> Ecto.Changeset.cast(params, [:name, :name_id, :owner_id, :description])
      |> Ecto.Changeset.validate_format(:name_id, ~r/^[a-z0-9_-]+$/i)
      |> Ecto.Changeset.validate_required([:name, :name_id, :owner_id])
      |> Ecto.Changeset.unique_constraint(:name_id)
    end
  end
end
