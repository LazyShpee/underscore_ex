defmodule UnderscoreEx.Consumer do
  @moduledoc false

  use Nostrum.Consumer
  require Logger
  alias UnderscoreEx.Core
  alias UnderscoreEx.Command

  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  def handle_event({:MESSAGE_CREATE, %{author: %{bot: bot}} = message, _ws_state})
      when bot != true do
    Core.run(message)
  end

  def handle_event({:READY, _, _ws_state}) do
    import UnderscoreEx.Core, only: [group: 1]

    %{
      "echo" => Command.Echo,
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
              "edit" => Command.Emoji.Network.Edit,
              "editguild" => Command.Emoji.Network.Edit.Guild,
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
