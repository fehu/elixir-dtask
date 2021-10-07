defmodule DTask.App.Tui.MixProject do
  use Mix.Project

  def project do
    [
      app: :dtask_tui,
      version: "0.2.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DTask.App.TUI, []}
           # :debug_no_tui
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dtask, in_umbrella: true},
      {:ratatouille, "~> 0.5.1"},
      {:tzdata, "~> 1.1"}
    ]
  end
end
