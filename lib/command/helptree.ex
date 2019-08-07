defmodule UnderscoreEx.Command.HelpTree do
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

  def walk_tree(acc, _command, _prefix, __opts) do
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
  def call(context, query) do
    result = Core.find_command_or_group(query)

    call_name =
      if query == "" do
        "."
      else
        String.slice(query, 0..(-String.length(result |> elem(3)) - 1))
        |> String.trim()
        |> String.replace(~r" +", "/")
      end

    with {:ok, :group, group, _rest, _depth} <- result do
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
      #{call_name}
      #{out}
      ```
      """
    else
      _ -> ""
    end
  end
end
