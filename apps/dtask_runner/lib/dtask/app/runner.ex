defmodule DTask.App.Runner do
  @moduledoc """
  Cluster runner (slave) application.

  Children:
    * Task executor (`DTask.Task.Executor`)
    * Resource usage reporter (`DTask.ResourceUsage.Reporter`)

  """
  use Application
  require Logger

  alias DTask.App
  alias DTask.ResourceUsage
  alias DTask.Task

  @app_name :dtask_runner

  @type config :: %{
                    master_node: atom,
                    exec_node_prefix: String.t,
                    resource_report_interval: non_neg_integer,
                    resource_usage: %{
                      extractor: ResourceUsage.Extractor.t,
                      params: ResourceUsage.Extractor.params
                    }
                  }

  def start(_type, _args) do
    cfg = Enum.into(Application.get_all_env(@app_name), %{})

    # Ensure node started
    App.ensure_node_alive!(cfg, :exec_node_prefix)

    children = [
      %{
        id: Task.Executor,
        start: {Task.Executor, :start_link, [
          {Task.Dispatcher, cfg.master_node},
          Task.Reporter.DispatcherReporter.Builder
        ]}
      },
      %{
        id: ResourceUsage.Reporter,
        start: {ResourceUsage.Reporter, :start_link, [
          {ResourceUsage.Collector, cfg.master_node},
          cfg.resource_report_interval,
          cfg.resource_usage.extractor,
          cfg.resource_usage.params
        ]}
      }
    ]

    # Start supervisor
    opts = [strategy: :one_for_one, name: DTask.App.Runner.Supervisor]
    supervisor = Supervisor.start_link(children, opts)

    # Connect to master node
    case Node.connect(cfg.master_node) do
      true -> Logger.notice("Connected to master node #{cfg.master_node}")
      _    -> raise "Failed to connect to node #{cfg.master_node}"
    end

    supervisor
  end
end
