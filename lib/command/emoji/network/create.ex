defmodule UnderscoreEx.Command.Emoji.Network.Create do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.Emoji.Network
  alias UnderscoreEx.Repo

  @impl true
  def parse_args(arg),
    do:
      [_, _]
      |> destructure(arg |> String.split(" ", parts: 2, trim: true))
      |> Enum.map(&(&1 || ""))
      |> List.to_tuple()

  @impl true
  def call(context, {name_id, name}) do
    Network.changeset(%Network{}, %{
      name_id: name_id,
      name: name,
      owner_id: "#{context.message.author.id}"
    })
    |> Repo.insert()
    |> case do
      {:ok, %{name_id: name_id, name: name}} ->
        "Emoji network **#{name}** has been created with id `#{name_id}`."

      {:error, %{errors: [{:name_id, {_, [{:constraint, :unique} | _]}} | _]}} ->
        "Network id is already in use."

      {:error, %{errors: [{:name_id, {_, [{:validation, :format} | _]}} | _]}} ->
        "Network id is not valid."

      {:error, _} ->
        "Error occurred."
    end
  end
end
