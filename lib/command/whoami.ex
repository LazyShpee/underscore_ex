defmodule UnderscoreEx.Command.Whoami do
  use UnderscoreEx.Command

  @impl true
  def call(context, _args) do
    user = Nostrum.Cache.UserCache.get!(context.message.author.id)
    """
    You are : #{user.username}##{user.discriminator}
    ID : `#{user.id}`
    Bot : #{user.bot && "yes" || "no"}
    """
  end
end
