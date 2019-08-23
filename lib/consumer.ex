defmodule UnderscoreEx.Consumer do
  @moduledoc false

  use Nostrum.Consumer
  require Logger
  alias UnderscoreEx.Core

  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  def my_handle_event({:MESSAGE_CREATE, %{author: %{bot: bot}} = message, _ws_state})
      when bot != true do
    Core.run(message)
  end

  def my_handle_event({:READY, _, _ws_state}) do
    alias UnderscoreEx.Command
    import UnderscoreEx.Core

    %{
      "whoami" => Command.Whoami,
      "su" => Command.Su,
      "syslist" => Command.SysList,
      "caca" =>
        group(
          %{
            "start" => Command.Caca.Start,
            "last" => Command.Caca.Last,
            "chaud" => Command.Caca.Show
          },
          Command.Caca
        ),
      "math" => Command.Math,
      "latex" => Command.Latex,
      "test" => Command.Test,
      "echo" => Command.Echo,
      "help" => Command.Help,
      "eval" => Command.Eval,
      "alias" =>
        group(
          %{
            "list" => Command.Alias.List,
            "show" => Command.Alias.Show,
            "delete" => Command.Alias.Delete,
            "set" => Command.Alias.Set
          },
          Command.Alias
        ),
      "emoji" =>
        group(
          %{
            "list" => Command.Emoji.List,
            "add" => Command.Emoji.Add,
            "delete" => Command.Emoji.Delete,
            "move" => Command.Emoji.Move,
            "network" =>
              group(
                %{
                  "create" => Command.Emoji.Network.Create,
                  "delete" => Command.Emoji.Network.Delete,
                  "show" => Command.Emoji.Network.Show,
                  "list" => Command.Emoji.Network.List,
                  "add" =>
                    group(%{
                      "guild" => Command.Emoji.Network.Add.Guild,
                      "manager" => Command.Emoji.Network.Add.Manager
                    }),
                  "edit" => Command.Emoji.Network.Edit,
                  "editguild" => Command.Emoji.Network.Edit.Guild,
                  "remove" =>
                    group(%{
                      "guild" => Command.Emoji.Network.Remove.Guild,
                      "manager" => Command.Emoji.Network.Remove.Manager
                    })
                },
                Command.Emoji.Network
              )
          },
          Command.Emoji
        )
    }
    |> Core.put_commands()

    Core.fetch_owner()
  end

  def my_handle_event(_event) do
    :noop
  end

  def handle_event({type, data, _ws_state} = event) do
    Core.EventRegistry.dispatch([{:discord, {type, data}}])
    my_handle_event(event)
  end
end
