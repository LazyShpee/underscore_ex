defmodule UnderscoreEx.Command.SysList do
  use UnderscoreEx.Command
  alias UnderscoreEx.Schema.SysListEntry
  alias UnderscoreEx.Repo
  import Ecto.Query, only: [from: 2]

  @impl true
  def predicates, do: [&UnderscoreEx.Predicates.bot_owner/1]

  @impl true
  def parse_args(arg), do: arg |> String.split(" ", trim: true, parts: 3)

  defp add_entry(entry) do
    case SysListEntry.changeset(%SysListEntry{}, entry) |> Repo.insert() do
      {:ok, _entry} ->
        "Added #{format_entry(entry)} to **#{entry.list_name}**."

      {:error, %{errors: [{:context_id, {_, [{:constraint, :unique} | _]}} | _]}} ->
        "Already present."

      e ->
        "```elixir\n#{inspect(e)}\n```"
    end
  end

  defp remove_entry(entry) do
    with entry when not is_nil(entry) <- Repo.get_by(SysListEntry, entry),
         {:ok, entry} <- Repo.delete(entry) do
      "Removed #{format_entry(entry)} from **#{entry.list_name}**."
    else
      _ -> "Nothing to remove."
    end
  end

  defp delete_list(name) do
    {n, _} = Repo.delete_all(from(e in SysListEntry, where: e.list_name == ^name))

    case n do
      0 -> "List was already empty."
      n -> "Emptied **#{name}**. (`#{n}`)"
    end
  end

  defp show_list(name) do
    entries =
      from(e in SysListEntry, where: e.list_name == ^name)
      |> Repo.all()
      |> Enum.sort(fn %{context_type: a}, %{context_type: b} -> a > b end)
      |> Enum.map(&format_entry/1)

    case length(entries) do
      0 -> "List is empty."
      _ -> entries |> Enum.join("\n")
    end
  end

  defp show_lists do
    lists =
      from(e in SysListEntry, group_by: e.list_name, select: {e.list_name, count(e.id)})
      |> Repo.all()
      |> Enum.map(fn {name, count} -> "#{name} - #{count}" end)
      |> Enum.sort()

    case length(lists) do
      0 -> "No lists."
      n -> "Found #{n} :\n#{lists |> Enum.join("\n")}"
    end
  end

  defp format_entry(%{context_type: "user" = context_type, context_id: context_id}) do
    case Nostrum.Cache.UserCache.get(context_id) do
      {:ok, user} -> "#{context_type} #{user.username}##{user.discriminator} (`#{user.id}`)"
      {:error, _} -> "#{context_type} `#{context_id}`"
    end
  end

  defp format_entry(%{context_type: "channel" = context_type, context_id: context_id}) do
    case Nostrum.Cache.ChannelCache.get(context_id) do
      {:ok, channel} -> "#{context_type} #{channel.name} (`#{channel.id}`)"
      {:error, _} -> "#{context_type} `#{context_id}`"
    end
  end

  defp format_entry(%{context_type: context_type, context_id: context_id}) do
    "#{context_type} `#{context_id}`"
  end

  @impl true
  def call(context, [name, action, query]) do
    with {:error, :not_found, _} <-
           UnderscoreEx.Util.resolve_user_id(query, context.message.guild_id)
           |> Tuple.append("user"),
         {:error, :not_found, _} <-
           UnderscoreEx.Util.resolve_channel_id(query, context.message.guild_id)
           |> Tuple.append("channel") do
      :error
    else
      {:ok, id, type} -> %{context_id: id, context_type: type, list_name: name}
    end
    |> case do
      :error -> "Could not resolve a user or a channel."
      %{} = entry when action in ["+", "add", "put"] -> entry |> add_entry()
      %{} = entry when action in ["-", "remove", "take"] -> entry |> remove_entry()
    end
  end

  @impl true
  def call(_context, [name, action]) do
    cond do
      action in ["show", "list", "?"] -> show_list(name)
      action in ["delete", "empty", "clear"] -> delete_list(name)
    end
  end

  @impl true
  def call(_context, [action]) when action in ["list", "show", "?"] do
    show_lists()
  end

  def call(_, []), do: :ok
end
