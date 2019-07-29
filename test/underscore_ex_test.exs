defmodule UnderscoreExTest do
  use ExUnit.Case
  doctest UnderscoreEx

  test "greets the world" do
    assert UnderscoreEx.hello() == :world
  end
end
