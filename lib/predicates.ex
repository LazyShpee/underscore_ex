defmodule UnderscoreEx.Predicates do
  require Logger

  def test(ret), do: fn _ctx -> ret end

  def context(ctx) do
    fn %{message: %{guild_id: guild_id}} ->
      case ctx do
        :guild when is_nil(guild_id) -> {:error, "This command is for guilds only."}
        :dm when not is_nil(guild_id) -> {:error, "This command is for DMs only."}
        _ -> :passthrough
      end
    end
  end

  def bot_owner(%{message: message}) do
    with true <- UnderscoreEx.Core.get_owner == message.author.id do
      :passthrough
    else
      _ -> {:error, "This command is for my owner only."}
    end
  end

  def need_app_env(keys) do
    fn %{unaliased_call_name: unaliased_call_name} ->
      missing =
        keys
        |> Enum.map(&{&1, Application.get_env(:underscore_ex, &1)})
        |> Enum.filter(fn
          {_, nil} -> true
          _ -> false
        end)

      case length(missing) do
        0 ->
          :passthrough

        n ->
          Logger.warn(
            "I'm missing #{n} key(s) to execute '#{unaliased_call_name}' configuration: #{
              missing |> Enum.map(&elem(&1, 0)) |> Enum.join(", ")
            }"
          )

          {:error, "I'm not configured properly to do that."}
      end
    end
  end

  def perms(perms, mode \\ :all) do
    fn %{message: message} = context ->
      with :passthrough <- context(:guild).(context),
           {:ok, user_perms} <-
             UnderscoreEx.Util.channel_permissions(
               message.author.id,
               message.guild_id,
               message.channel_id
             ),
           {:perms, true} <-
             {:perms, UnderscoreEx.Util.has_permissions?(user_perms, perms, mode)} do
        :passthrough
      else
        {:error, <<_reason::binary>>} ->
          # Always ok in DMs
          :passthrough

        _ ->
          {:error,
           "You need #{mode} permission(s) in: #{perms |> Enum.map(&"`#{&1}`") |> Enum.join(", ")}"}
      end
    end
  end

  def syslists(lists, blacklist \\ false) do
    alias UnderscoreEx.Repo
    alias UnderscoreEx.Schema.SysListEntry
    import Ecto.Query, only: [from: 2]

    fn %{message: %{channel_id: channel_id, author: %{id: user_id}}} ->
      from(e in SysListEntry,
        where:
          e.list_name in ^lists and
            ((e.context_type == ^"channel" and e.context_id == ^channel_id) or
               (e.context_type == ^"user" and e.context_id == ^user_id))
      )
      |> Repo.all()
      |> length()
      |> case do
        0 when blacklist ->
          :passthrough

        _ when blacklist ->
          {:error, "Either you or this channel is blacklisted."}

        0 when not blacklist ->
          {:error, "Either you or this channel is not whitelisted to use this command."}

        _ when not blacklist ->
          :passthrough
      end
    end
  end

  def my_perms(perms, mode \\ :all) do
    fn %{message: message} = context ->
      %{id: id} = Nostrum.Cache.Me.get()

      with :passthrough <- context(:guild).(context),
           {:ok, user_perms} <-
             UnderscoreEx.Util.channel_permissions(
               id,
               message.guild_id,
               message.channel_id
             ),
           {:perms, true} <-
             {:perms, UnderscoreEx.Util.has_permissions?(user_perms, perms, mode)} do
        :passthrough
      else
        {:error, <<_reason::binary>>} ->
          # Always ok in DMs
          :passthrough

        _ ->
          {:error,
           "I need need #{mode} permission(s) in: #{
             perms |> Enum.map(&"`#{&1}`") |> Enum.join(", ")
           }"}
      end
    end
  end
end
