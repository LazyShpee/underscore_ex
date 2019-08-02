defmodule UnderscoreEx.Command.Emoji.Network.Edit do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.Emoji.Network
  alias UnderscoreEx.Repo

  @impl true
  def parse_args(arg),
    do:
      [_, _, _]
      |> destructure(arg |> String.split(" ", parts: 3, trim: true))
      |> Enum.map(&(&1 || ""))
      |> List.to_tuple()

  @impl true
  @editable [:name_id, :name]
  def call(context, {network_id, key_str, value_str}) do
    key = String.to_atom(key_str)

    with true <- key in @editable,
         %{^key => old} = network <-
           Repo.get_by(Network, %{name_id: network_id, owner_id: "#{context.message.author.id}"}),
         {:ok, %{^key => new}} <-
           Network.changeset(network, %{key => value_str}) |> Repo.update() do
      "📝 Edited `#{key}` : `#{old}` -> `#{new}`."
    else
      nil ->
        "This network doesn't exist or isn't yours."

      false ->
        "Key must be one of #{@editable |> Enum.map(&"`#{&1}`") |> Enum.join(", ")}."

      {:error, %{errors: [{:name_id, {_, [{:constraint, :unique} | _]}} | _]}} ->
        "This name_id is already in use."

      {:error, %{errors: [{:name_id, {_, [{:validation, :format} | _]}} | _]}} ->
        "This name_id is not valid."
    end
  end
end
