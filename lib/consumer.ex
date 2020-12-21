defmodule UnderscoreEx.Consumer do
  @moduledoc false

  use Nostrum.Consumer
  require Logger
  alias UnderscoreEx.Core

  def start_link() do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  def my_handle_event({:MESSAGE_CREATE, %{author: %{bot: bot}} = message, _ws_state})
      when bot != true do
    Core.run(message)
  end

  def my_handle_event({:MESSAGE_REACTION_ADD, data, _ws_state}) do
    UnderscoreEx.Command.Creajam.handle_reaction(:add, data)
  end

  def my_handle_event({:MESSAGE_REACTION_REMOVE, data, _ws_state}) do
    UnderscoreEx.Command.Creajam.handle_reaction(:remove, data)
  end

  def my_handle_event({:READY, _, _ws_state}) do
    alias UnderscoreEx.Command
    import UnderscoreEx.Core

    %{
      "im" => Command.IM,
      # Public commands
      "google" => Command.Google,
      "info" => Command.Info,
      "stack" => Command.Stack,
      "text" => Command.Text,
      "chrole" => Command.ChRole,
      "code" => Command.Code,
      "tio" => Command.TIO,
      "cfg" => Command.CFG,
      "whoami" => Command.Whoami,
      "su" => Command.Su,
      "syslist" => Command.SysList,
      "caca" =>
        group(
          %{
            "start" => Command.Caca.Start,
            "last" => Command.Caca.Last,
            "chaud" => Command.Caca.Show,
            "cancel" => Command.Caca.Cancel
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
            "prepare" => Command.Emoji.Prepare,
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
        ),
      "role" =>
        group(%{
          "permview" => Command.Role.PermView,
          "info" => Command.Role.Info
        }),
      "creajam" =>
        group(
          %{
            "reroll" => Command.Creajam.RerollMeme,
            "noreroll" => Command.Creajam.NoRerollMeme,
            "gentheme" => Command.Creajam.GenTheme
          },
          Command.Creajam
        )
    }
    |> Core.put_commands()

    Core.fetch_owner()
  end

  def my_handle_event(
        {:VOICE_STATE_UPDATE,
         %{user_id: user_id, session_id: session_id, guild_id: guild_id, channel_id: channel_id},
         _ws_state}
      )
      when not is_nil(channel_id) do
    %{id: id} = Nostrum.Cache.Me.get()

    if id === user_id do
      Core.EventRegistry.subscribe()

      receive do
        {:discord, {:VOICE_SERVER_UPDATE, %{guild_id: ^guild_id} = event}} ->
          Apatite.voice_server_update(session_id, event)
      end

      Core.EventRegistry.unsubscribe(:nokill)
    end
  end

  def my_handle_event({:VOICE_SERVER_UPDATE, data, _ws_state}) do
    IO.inspect(data)
  end

  def my_handle_event({_type, _data, _ws_state}) do
    :noop
  end

  def handle_event({type, data, _ws_state} = event) do
    Core.EventRegistry.dispatch([{:discord, {type, data}}])
    my_handle_event(event)
  end
end
