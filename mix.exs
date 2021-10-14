defmodule DTaskUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      app: :dtask_umbrella,
      apps_path: "apps",
      version: "0.2.1-SNAPSHOT",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [{:dialyxir, "~> 1.1.0", only: [:dev], runtime: false}]
  end
end
