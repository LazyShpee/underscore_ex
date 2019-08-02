defmodule UnderscoreEx.Core do
  @moduledoc false

  use GenServer

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

  def run_command(command, args) do
    {:ok, apply(command, :call, args)}
  rescue
    e -> {:error, e}
  end

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
      nil -> {:error, :not_a_command}
      _ -> {:ok, message.content |> String.slice(String.length(prefix)..-1), normal_prefix}
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
