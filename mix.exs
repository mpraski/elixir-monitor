defmodule Monitor.MixProject do
  use Mix.Project

  def project do
    [
      app: :monitor,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    Application.ensure_all_started(:yaml_elixir)

    [
      extra_applications: [:logger],
      mod: {Monitor.Application, []},
      env: [
        initial_store: %{},
        initial_urls: load_config("urls.yml")
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:httpoison, "~> 1.2"},
      {:yaml_elixir, "~> 2.1.0"},
      {:poolboy, "~> 1.5"},
    ]
  end

  defp load_config(file) do
    path = File.cwd!() |> Path.join(file)
    YamlElixir.read_from_file(path)
  end
end
