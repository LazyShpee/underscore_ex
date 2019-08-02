defmodule UnderscoreEx.Consumer do
  @moduledoc false

  use Nostrum.Consumer
  require Logger
  alias UnderscoreEx.Core
  alias UnderscoreEx.Util
  alias UnderscoreEx.Command

  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  def handle_event({:MESSAGE_CREATE, %{author: %{bot: bot}} = message, _ws_state})
      when bot != true do
    context = %{message: message}

    with {:ok, command_line, prefix} <- context |> Core.extract_command(),
         {:ok, command_line, alias_call_name} <-
           command_line
           |> Command.Alias.resolve(message.guild_id || message.author.id),
         {:ok, type, item, rest, depth} when depth > 0 <-
           Core.find_command_or_group(command_line),
         call_name <- String.slice(command_line, 0..(-String.length(rest) - 1)) |> String.trim(),
         {:ok, command} <- Core.get_command(item),
         context <-
           %{
             rest: rest,
             prefix: prefix,
             self: {type, item, depth},
             call_name: alias_call_name || call_name,
             unaliased_call_name: call_name
           }
           |> Enum.into(context),
         {:ok} <- command.predicates |> Core.check_predicates(context),
         args <- command.parse_args(rest),
         {:ok, result} <- Core.run_command(command, [context, args]) do
      case result do
        <<reply::binary>> -> reply |> Util.pipe_message(message)
        _ -> nil
      end
    else
      {:error, <<reason::binary>>} ->
        "Error: #{reason}" |> Util.pipe_message(message)

      {:error, :not_a_command} ->
        nil

      {:ok, _type, _item, _rest, _depth} ->
        Logger.warn("Could not find command for '#{message.content}'.")

      {:error, :no_command} ->
        Logger.warn("No executable command for group '#{message.content}'.")

      {:error, :no_commands} ->
        Logger.error("No commands loaded yet.")

      e ->
        Logger.warn("Unhandled error: #{inspect(e)}")
    end
  end

  def handle_event({:READY, _, _ws_state}) do
    import UnderscoreEx.Core, only: [group: 2, group: 1]

    %{
      "helptree" => Command.HelpTree,
      "help" => Command.HelpTree,
      "eval" => Command.Eval,
      "alias" =>
        group(%{
          "list" => Command.Alias.List,
          "show" => Command.Alias.Show,
          "delete" => Command.Alias.Delete,
          "set" => Command.Alias.Set
        }),
      "emoji" =>
        group(%{
          "add" => Command.Emoji.Add,
          "delete" => Command.Emoji.Delete,
          "move" => Command.Emoji.Move,
          "network" =>
            group(%{
              "create" => Command.Emoji.Network.Create,
              "delete" => Command.Emoji.Network.Delete,
              "show" => Command.Emoji.Network.Show,
              "list" => Command.Emoji.Network.List,
              "add" =>
                group(%{
                  "guild" => Command.Emoji.Network.Add.Guild
                  # "manager" => Command.Emoji.Network.Add.Manager
                }),
              "edit" =>
                group(
                  %{
                    "guild" => Command.Emoji.Network.Edit.Guild
                    # "manager" => Null
                  },
                  Command.Emoji.Network.Edit
                ),
              "remove" =>
                group(%{
                  "guild" => Command.Emoji.Network.Remove.Guild
                  # "manager" => Null
                })
            })
        })
    }
    |> Core.put_commands()
  end

  def handle_event(_event) do
    :noop
  end
end
