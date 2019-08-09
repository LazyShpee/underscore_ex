defmodule UnderscoreEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :underscore_ex,
      version: "0.1.0",
      elixir: "~> 1.8",
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
      extra_applications: [:logger],
      mod: {UnderscoreEx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, git: "https://github.com/Kraigie/nostrum.git"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:ex_doc, "~> 0.19"},
      {:httpoison, "~> 1.4"}
    ]
  end
end
