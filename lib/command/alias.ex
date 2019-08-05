defmodule UnderscoreEx.Command.Alias do
  use UnderscoreEx.Command

  alias UnderscoreEx.Util
  alias UnderscoreEx.Schema.Alias
  alias UnderscoreEx.Repo

  def create_or_modify(name, context, %{} = changes) do
    case Repo.get_by(Alias, context: context, name: name) do
      nil -> %Alias{name: name, context: context}
      al -> al
    end
    |> Alias.changeset(changes)
    |> Repo.insert_or_update()
  end

  def delete(name, context) do
    with {:ok, al} <- get(name, context),
         {:ok, del_al} <- Repo.delete(al) do
      {:ok, del_al}
    else
      err -> err
    end
  end

  def get(name, context) do
    case Repo.get_by(Alias, context: context, name: name) do
      nil -> {:error, :not_found}
      al -> {:ok, al}
    end
  end

  defp unescape(stuff) do
    stuff
    |> String.replace("::", ";;")
  end

  def resolve(command, nil), do: {:ok, command, command}

  def resolve(command, context) do
    destructure([name, rest], command |> String.split(" ", parts: 2, trim: true))

    with {:ok, al} <- get(name, Integer.to_string(context)) do
      {:ok, unescape(al.content) <> " " <> (rest || ""), name}
    else
      _ -> {:ok, command, nil}
    end
  end

  @impl true
  def usage,
    do: [
      "set <alias name> <alias content>",
      "show <alias name>",
      "list",
      "delete <alias name>"
    ]

  @impl true
  def call(%{call_name: call_name}, _args),
    do: """
    ```css
    #{
      usage()
      |> Enum.map(&"#{call_name} #{&1}")
      |> Enum.join("\n")
    }
    ```
    """

  defmodule List do
    use UnderscoreEx.Command

    alias UnderscoreEx.Schema.Alias
    alias UnderscoreEx.Repo
    import Ecto.Query, only: [from: 2]

    @impl true
    def call(context, _args) do
      aliases =
        from(a in Alias,
          where: a.context == ^"#{context.message.guild_id || context.message.author.id}",
          order_by: a.name
        )
        |> Repo.all()

      case length(aliases) do
        0 -> "There are no aliases here."
        _n -> aliases |> Enum.map(fn a -> "`#{a.name}`" end) |> Enum.join(", ")
      end
    end
  end

  defmodule Show do
    use UnderscoreEx.Command

    @impl true
    def parse_args(arg), do: arg

    @impl true
    def call(context, rest) do
      with true <- rest != "",
           {:ok, al} <-
             UnderscoreEx.Command.Alias.get(
               rest,
               Integer.to_string(context.message.guild_id || context.message.author.id)
             ) do
        "Alias `#{al.name}` is set to `#{al.content}`."
      else
        {:error, :not_found} -> "Alias `#{rest}` does not exist."
        _ -> Util.usage("<name>", context)
      end
    end
  end

  defmodule Set do
    use UnderscoreEx.Command

    @impl true
    def parse_args(arg), do: arg

    @impl true
    def predicates, do: [UnderscoreEx.Predicates.perms([:manage_guild])]

    @impl true
    def call(context, rest) do
      with {:parts, [name, content]} <-
             {:parts, rest |> String.split(" ", parts: 2, trim: true)},
           false <- name == "alias" do
        UnderscoreEx.Command.Alias.create_or_modify(
          name,
          Integer.to_string(context.message.guild_id || context.message.author.id),
          %{content: content, author: Integer.to_string(context.message.author.id)}
        )

        "Set alias `#{name}` to `#{content}`."
      else
        true ->
          "`alias` is a reserved name."

        e ->
          IO.inspect(e)
          Util.usage("<name> <aliased command>", context)
      end
    end
  end

  defmodule Delete do
    use UnderscoreEx.Command

    @impl true
    def parse_args(arg), do: arg

    @impl true
    def predicates, do: [UnderscoreEx.Predicates.perms([:manage_guild])]

    @impl true
    def call(context, rest) do
      with true <- rest != "",
           {:ok, al} <-
             UnderscoreEx.Command.Alias.delete(
               rest,
               Integer.to_string(context.message.guild_id || context.message.author.id)
             ) do
        "Deleted `#{al.name}`."
      else
        {:error, :not_found} -> "Alias `#{rest}` does not exist."
        _ -> Util.usage("<name>", context)
      end
    end
  end
end
