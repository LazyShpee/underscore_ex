defmodule UnderscoreEx.Command.Help do
  use UnderscoreEx.Command
  alias UnderscoreEx.Core

  @impl true
  def parse_args(arg), do: arg

  # Thank god for https://github.com/kddeisz/tree/blob/master/tree.exs
  def walk_tree(group, opts \\ []) do
    walk_tree([], group, opts[:prefix] || "", opts)
  end

  def walk_tree(acc, %{commands: commands}, prefix, opts) do
    entries =
      if is_nil(opts[:filter]) do
        commands
      else
        opts[:filter].(commands)
      end
      |> Enum.with_index()

    total = entries |> Enum.count()

    Enum.reduce(entries, acc, fn {{_name, data} = entry, index}, acc ->
      {line, new_prefix} = output(prefix, entry, index, total, opts)
      walk_tree(acc |> List.insert_at(-1, line), data, new_prefix, opts)
    end)
  end

  def walk_tree(acc, _command, _prefix, _opts) do
    acc
  end

  defp output(prefix, {name, _} = entry, index, total, opts) do
    name =
      if is_nil(opts[:format]) do
        name
      else
        opts[:format].(entry)
      end

    output(prefix, name, index, total, opts)
  end

  defp output(prefix, name, index, total, opts) when index == total - 1 do
    if opts[:ascii] do
      {"#{prefix}`-- #{name}", "#{prefix}    "}
    else
      {"#{prefix}└── #{name}", "#{prefix}    "}
    end
  end

  defp output(prefix, name, _index, _total, opts) do
    if opts[:ascii] do
      {"#{prefix}|-- #{name}", "#{prefix}|   "}
    else
      {"#{prefix}├── #{name}", "#{prefix}│   "}
    end
  end

  @impl true
  def call(context, <<"--tree", query::binary>>) do
    result = Core.find_command_or_group(query |> String.trim())

    call_name =
      if query == "" do
        "UnderscoreEx"
      else
        String.slice(query, 0..(-String.length(result |> elem(3)) - 1))
        |> String.trim()
      end

    make_group_tree(result, context, call_name)
  end

  @impl true
  def call(context, query) do
    result = Core.find_command_or_group(query)

    call_name =
      if query == "" do
        "UnderscoreEx"
      else
        String.slice(query, 0..(-String.length(result |> elem(3)) - 1))
        |> String.trim()
      end

    fields =
      with {:ok, command} <- Core.get_command(result |> elem(2)),
           {:ok} <- Core.check_predicates(command, context) do
        [] ++
          [
            %Nostrum.Struct.Embed.Field{
              name: "Description",
              value:
                case apply(command, :description, []) do
                  "" -> "*No description*"
                  desc -> desc
                end
            }
          ] ++
          case apply(command, :usage, []) do
            [] ->
              []

            usage ->
              [
                %Nostrum.Struct.Embed.Field{
                  name: "Usage",
                  value: """
                  ```
                  #{usage |> Enum.map(&"#{call_name} #{&1}") |> Enum.join("\n")}
                  ```
                  """
                }
              ]
          end
      else
        _ -> []
      end ++
        make_group_categories(result, context)

    [
      embed: %Nostrum.Struct.Embed{
        title: call_name,
        description: String.duplicate("─", 30),
        fields: fields
      }
    ]
  end

  defp make_group_categories({:ok, :group, %{commands: commands}, _rest, _depth}, context) do
    commands
    |> Enum.filter(&(Core.check_predicates(&1 |> elem(1), context) == {:ok}))
    |> Enum.map(fn {name, data} ->
      {:ok, cmd} = Core.get_command(data)
      {apply(cmd, :category, []), name}
    end)
    |> Enum.group_by(fn {k, _} -> k end, fn {_, x} -> x end)
    |> Enum.map(fn {name, names} ->
      %Nostrum.Struct.Embed.Field{
        name: name,
        value: names |> Enum.map(&"`#{&1}`") |> Enum.join(" ")
      }
    end)
  end

  defp make_group_categories(_, _), do: []

  defp make_group_tree(
         {:ok, :group, group, _rest, _depth},
         context,
         call_name
       ) do
    out =
      group
      |> walk_tree(
        ascii: true,
        filter: fn entries ->
          entries
          |> Enum.filter(fn
            {_, data} -> Core.check_predicates(data, context) == {:ok}
          end)
          |> Enum.sort(fn {a, _}, {b, _} -> a < b end)
        end
      )
      |> Enum.join("\n")

    """
    ```
    #{call_name |> String.replace(~r" +", "/")}
    #{out}
    ```
    """
  end

  defp make_group_tree(_, _, _), do: "*No tree*"

  @impl true
  def usage,
    do: [
      "",
      "<command>",
      "--tree [command]"
    ]

  @impl true
  def description,
    do: """
    The help command. It can be used to see detailled command help if available, sub commands if any and a tree style view of the commands (see usage).
    """
end
