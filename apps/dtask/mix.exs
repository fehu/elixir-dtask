defmodule DTask.MixProject do
  use Mix.Project

  def project do
    [
      app: :dtask,
      version: "0.1.0",
      elixir: "~> 1.12",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
       {:dialyxir, "~> 1.1.0", only: [:dev], runtime: false}
    ]
  end
end
