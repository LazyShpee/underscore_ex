defmodule UnderscoreEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :underscore_ex,
      version: "0.1.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :abacus, :timex],
      mod: {UnderscoreEx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, git: "https://github.com/Kraigie/nostrum.git"},
      {:ecto_sql, "~> 3.5"},
      {:postgrex, "~> 0.15"},
      {:ex_doc, "~> 0.19"},
      {:httpoison, "~> 1.7"},
      {:abacus, "~> 0.4.2"},
      {:timex, "~> 3.6"},
      {:exredis, "~> 0.3"},
      {:rambo, "~> 0.3"},
      {:erlcron, git: "https://github.com/erlware/erlcron.git"},
      {:tzdata, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.2"},
    ]
  end
end
