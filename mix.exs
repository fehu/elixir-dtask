defmodule DTaskUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      # app: :dtask_umbrella,
      apps_path: "apps",
      version: "0.2.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
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

  defp releases, do: [
    ctrl: release_app(:dtask_controller),
    exec: release_app(:dtask_runner),
    tui:  release_app(:dtask_tui)
  ]

  defp release_app(app), do: [
    applications: [{app, :permanent}],
    include_executables_for: release_platforms(),
    cookie: cookie()
  ]

  defp release_platforms, do: [:unix]

  defp cookie, do: "XjO7upm1372WLGWwe_6DSUhZXdl4-UaeiRyl3ZxWfKSEv6AN3idQ9A"
end
