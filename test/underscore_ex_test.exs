defmodule UnderscoreExTest do
  use ExUnit.Case
  doctest UnderscoreEx

  test "emoji path resolve" do
    assert UnderscoreEx.Command.Emoji.resolve_emoji_path("network/guild/emoji", 12345) ==
             {"network", "guild", "emoji"}

    assert UnderscoreEx.Command.Emoji.resolve_emoji_path("guild/emoji", 12345) ==
             {"", "guild", "emoji"}

    assert UnderscoreEx.Command.Emoji.resolve_emoji_path("emoji", 12345) == {"", "12345", "emoji"}
  end
end
