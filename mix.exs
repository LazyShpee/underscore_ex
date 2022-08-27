defmodule UnderscoreEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :underscore_ex,
      version: "0.2.1",
      elixir: "~> 1.12",
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
      {:nostrum, git: "https://github.com/Kraigie/nostrum.git", tag: "v0.6.1"},
      {:ecto_sql, "~> 3.8"},
      {:postgrex, "~> 0.16"},
      {:ex_doc, "~> 0.28"},
      {:httpoison, "~> 1.8"},
      {:poison, "~> 5.0"},
      {:abacus, "~> 2.0"},
      {:timex, "~> 3.7"},
      {:jason, "~> 1.3"},
      {:exredis, "~> 0.3"},
      {:rambo, "~> 0.3"},
      {:erlcron, git: "https://github.com/erlware/erlcron.git"},
      {:tzdata, "~> 1.1"},
      {:plug_cowboy, "~> 2.5"},
      {:cowlib, "~> 2.11", hex: :remedy_cowlib, override: true},
    ]
  end
end
