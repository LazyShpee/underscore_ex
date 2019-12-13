defmodule UnderscoreEx.Command.Emoji.Network.Create do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.Emoji.Network
  alias UnderscoreEx.Repo

  @impl true
  def parse_args(arg),
    do:
      arg
      |> String.split(" ", parts: 2, trim: true)
      |> List.to_tuple()

  @impl true
  def call(context, {name_id, name}) when not is_nil(name_id) and not is_nil(name) do
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

      {:error, %{errors: [{:name, {_, [{:validation, :required} | _]}} | _]}} ->
        "Network name can't be blank"

      {:error, e} ->
        IO.inspect(e)
        "Unknown error occurred."
    end
  end

  @impl true
  def call(context, _args), do: UnderscoreEx.Command.Help.call(context, context.unaliased_call_name)

  @impl true
  def usage,
    do: [
      "<network name id> <network name>"
    ]
end
