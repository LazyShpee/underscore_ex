defmodule UnderscoreEx.Core do
  @moduledoc false

  use GenServer
  require Logger
  alias UnderscoreEx.Command
  alias UnderscoreEx.Util

  # expand(): split -> map(resolve_alias, if resolved, expand) -> flatten

  @escaper "\\"
  defp split_commands(str, splitter \\ ";;") do
    subs =
      [@escaper, splitter]
      |> Enum.with_index()
      |> Enum.map(&{elem(&1, 0), List.to_string([elem(&1, 1) + 1])})

    subs
    |> Enum.reduce(str, fn {o, r}, acc ->
      acc
      |> String.replace("#{@escaper}#{o}", r)
    end)
    |> String.split(";;", trim: true)
    |> Enum.map(fn e ->
      subs
      |> Enum.reduce(e, fn {o, r}, acc ->
        acc
        |> String.replace(r, o)
        |> String.trim()
      end)
    end)
  end

  def expand_commands(line, alias_context, depth \\ 0) do
    line
    |> split_commands()
    |> Enum.flat_map(fn part ->
      {:ok, line, _call_name} = part |> Command.Alias.resolve(alias_context)

      cond do
        part == line -> [line]
        depth >= 3 -> raise "Too many embedded aliases."
        true -> expand_commands(line, alias_context, depth + 1)
      end
    end)
  rescue
    e -> {:error, e.message}
  end

  def run(message) do
    context = %{message: message}

    with {:ok, command_line, prefix} <- extract_command(context),
         commands when is_list(commands) <-
           expand_commands(command_line, message.guild_id || message.author.id),
         context <-
           %{
             prefix: prefix
           }
           |> Enum.into(context),
         {:ok, result} <-
           run_commands(commands, context) do
      result
      |> Enum.filter(fn r -> is_binary(r) end)
      |> Enum.map(&String.trim/1)
      |> Enum.join("\n")
      |> Util.pipe_message(message)
    else
      {:error, <<reason::binary>>} ->
        "Error: #{reason}" |> Util.pipe_message(message)

      {:error, :not_a_command} ->
        nil

      {:ok, _type, _item, rest, _depth} ->
        Logger.warn("Could not find command for '#{rest}'.")

      {:error, :no_command} ->
        Logger.warn("No executable command for group '#{message.content}'.")

      {:error, :no_commands} ->
        Logger.error("No commands loaded yet.")

      e ->
        Logger.warn("Unhandled error: #{inspect(e)}")
    end
  end

  def run_commands(commands, context) do
    commands
    |> Enum.reduce_while({:ok, []}, fn command, {:ok, acc} ->
      case run_command(command, context) do
        {:ok, out} -> {:cont, {:ok, acc ++ [out]}}
        e -> {:halt, e}
      end
    end)
  end

  def run_command(command, context) do
    with {:ok, type, item, rest, depth} when depth > 0 <-
           find_command_or_group(command),
         call_name <-
           String.slice(command, 0..(-String.length(rest) - 1)) |> String.trim(),
         {:ok, command} <- get_command(item),
         context <-
           %{
             rest: rest,
             self: {type, item, depth},
             call_name: call_name,
             unaliased_call_name: call_name
           }
           |> Enum.into(context),
         {:ok} <- command.predicates |> check_predicates(context),
         args <- command.parse_args(rest) do
      {:ok, apply(command, :call, [context, args])}
    end
  rescue
    e -> {:error, e}
  end

  def find_command_or_group(query) do
    state = get_state()

    case state.commands do
      nil -> {:error, :no_commands}
      commands -> query |> find_command_or_group(commands)
    end
  end

  defp find_command_or_group(query, %{commands: commands} = group, depth \\ 0) do
    destructure([name, rest], query |> String.split(" ", parts: 2, trim: true))

    case commands[name] do
      nil -> {:ok, :group, group, query || "", depth}
      %{} = group -> find_command_or_group(rest || "", group, depth + 1)
      command -> {:ok, :command, command, rest || "", depth + 1}
    end
  end

  def get_command(%{command: command}) when not is_nil(command), do: {:ok, command}
  def get_command(%{}), do: {:error, :no_command}
  def get_command(command), do: {:ok, command}

  def check_predicates(predicates, context) do
    predicates
    |> Enum.reduce_while(:passthrough, fn pred, _acc ->
      case pred.(context) do
        :passthrough -> {:cont, :passthrough}
        {:error, _reason} = err -> {:halt, err}
      end
    end)
    |> case do
      :passthrough -> {:ok}
      e -> e
    end
  end

  def extract_command(%{message: message}) do
    state = get_state()
    me = Nostrum.Cache.Me.get()
    normal_prefix = state.prefixes[message.guild_id] || state.prefixes[:global]
    valid_prefixes = [normal_prefix, "<@#{me.id}>", "<@!#{me.id}>"]

    prefix =
      valid_prefixes
      |> Enum.find(fn
        nil -> nil
        p -> String.starts_with?(message.content, p)
      end)

    case prefix do
      nil ->
        {:error, :not_a_command}

      _ ->
        {:ok, message.content |> String.slice(String.length(prefix)..-1) |> String.trim(),
         normal_prefix}
    end
  end

  def group(commands, command \\ UnderscoreEx.Command.GroupHelper) do
    %{
      commands: commands,
      command: command
    }
  end

  def get_state() do
    GenServer.call(__MODULE__, :copy)
  end

  def put_commands(commands) do
    GenServer.call(__MODULE__, {:put_commands, commands})
  end

  #########################################
  # Server callbacks

  def start_link(_opts) do
    GenServer.start_link(
      __MODULE__,
      %{
        prefixes: %{
          global: Application.get_env(:underscore_ex, :prefix) || ">"
        },
        commands: nil
      },
      name: __MODULE__
    )
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:put_commands, commands}, _from, state) do
    {:reply, :ok, %{state | commands: %{commands: commands}}}
  end

  def handle_call(:copy, _from, state) do
    {:reply, state, state}
  end
end
