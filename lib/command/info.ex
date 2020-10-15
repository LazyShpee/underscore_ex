defmodule UnderscoreEx.Command.Info do
  use UnderscoreEx.Command
  import Nostrum.Struct.Embed

  @commit System.cmd("git", ["rev-parse", "--short", "HEAD"])

  @impl true
  def call(_, _) do
    commit =
      with {commit, 0} <- @commit do
        commit
      else
        _ -> "Unkown"
      end

    [
      embed:
        %Nostrum.Struct.Embed{}
        |> put_author("UnderscoreEx / __", "https://github.com/LazyShpee/underscore_ex", "")
        |> put_description("Made with [Elixir](https://elixir-lang.org/) and [Nostrum](https://github.com/Kraigie/nostrum/) by [LazyShpee](https://github.com/LazyShpee/)")
        |> put_field("Current commit", "`#{commit}`")
    ]
  end
end
