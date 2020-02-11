defmodule UnderscoreEx.Command do
  @callback usage() :: [String.t()]

  @callback predicates() :: [
              (context :: Map.t() -> :passthrough | {:error, String.t()})
            ]

  @callback call(context :: Map.t(), args :: [String.t()] | any()) :: String.t() | any()

  @callback parse_args(arg :: String.t()) :: any()

  @callback description() :: String.t()

  @callback category() :: String.t()

  @optional_callbacks usage: 0, predicates: 0, description: 0, parse_args: 1, category: 0

  defmacro __using__(_opts \\ []) do
    quote do
      @moduledoc false
      @behaviour unquote(__MODULE__)

      @impl true
      def usage, do: []
      @impl true
      def predicates, do: []
      @impl true
      def parse_args(arg), do: arg |> String.split()
      @impl true
      def description, do: ""
      @impl true
      def category, do: "Misc"
      @impl true
      def call(_context, _args), do: :ok

      defoverridable usage: 0, predicates: 0, parse_args: 1, description: 0, call: 2, category: 0
    end
  end
end
