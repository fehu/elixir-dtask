defmodule DTask.Task.Codec.MixProject do
  use Mix.Project

  def project do
    [
      app: :dtask_codec,
      version: "0.2.1",
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
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dtask, in_umbrella: true},
      {:jason, "~> 1.2"},
      {:stream_data, "~> 0.5", only: [:test]}
    ]
  end
end
