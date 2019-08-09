defmodule UnderscoreEx.Command.GroupHelper do
  use UnderscoreEx.Command

  defmacro __using__(_opts \\ []) do
    quote do
      use UnderscoreEx.Command

      defdelegate call(context, args), to: unquote(__MODULE__)
      defdelegate parse_args(arg), to: unquote(__MODULE__)
    end
  end

  @impl true
  def parse_args(arg) do
    arg
    |> String.split(" ", parts: 2, trim: true)
  end

  @impl true
  def call(
        %{
          self: {:group, %{commands: commands, command: command}, _depth},
          call_name: call_name,
          prefix: prefix
        },
        args
      )
      when not is_nil(commands) do
    names = commands |> Enum.map(&elem(&1, 0))

    case Enum.at(args, 0) do
      nil ->
        desc =
          case apply(command, :description, []) do
            "" -> "*No description available*"
            d -> d
          end

        [
          embed: %Nostrum.Struct.Embed{
            title: call_name,
            description: desc,
            color: 0x313337,
            fields: [
              %Nostrum.Struct.Embed.Field{
                name: "Sub commands",
                value: names |> Enum.map(&"`#{&1}`") |> Enum.join(", ")
              }
            ]
          }
        ]

      query ->
        guess =
          names
          |> Enum.map(fn name -> {name, abs(String.jaro_distance(name, query))} end)
          |> Enum.sort(&(elem(&1, 1) > elem(&2, 1)))
          |> Enum.at(0)
          |> elem(0)

        "Did you mean `#{prefix}#{call_name} #{guess}#{Enum.at(args, 1) && " "}#{Enum.at(args, 1)}` ?"
    end
  end
end
