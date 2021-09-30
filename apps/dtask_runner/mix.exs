defmodule DTask.App.Runner.MixProject do
  use Mix.Project

  def project do
    [
      app: :dtask_runner,
      version: "0.2.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      start_permanent: Mix.env() == :prod,
      deps: [{:dtask, in_umbrella: true}]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DTask.App.Runner, []}
    ]
  end
end
