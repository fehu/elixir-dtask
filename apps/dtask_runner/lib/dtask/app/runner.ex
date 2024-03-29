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
                    ctrl_node: atom,
                    exec_node_prefix: String.t,
                    resource_report_interval: non_neg_integer,
                    resource_usage: %{
                      extractor: ResourceUsage.Extractor.t,
                      params: ResourceUsage.Extractor.params
                    }
                  }

  @impl true
  def start(_type, _args) do
    cfg = Enum.into(Application.get_all_env(@app_name), %{})

    # Ensure node started
    App.ensure_node_alive!(cfg, :exec_node_prefix)

    children = [
      %{
        id: Task.Executor,
        start: {Task.Executor, :start_link, [
          {Task.Dispatcher, cfg.ctrl_node},
          Task.Reporter.MonitorBroadcastReporter.Builder
        ]},
        type: :worker,
        restart: :transient,
        shutdown: 100
      },
      %{
        id: ResourceUsage.Reporter,
        start: {ResourceUsage.Reporter, :start_link, [
          cfg.resource_report_interval,
          cfg.resource_usage.extractor,
          cfg.resource_usage.params
        ]},
        type: :worker,
        restart: :transient,
        shutdown: 100
      }
    ]

    # Start supervisor
    opts = [strategy: :one_for_one, name: DTask.App.Runner.Supervisor]
    supervisor = Supervisor.start_link(children, opts)

    # Connect to master node
    case Node.connect(cfg.ctrl_node) do
      true -> Logger.notice("Connected to control node #{cfg.ctrl_node}")
      _    -> raise "Failed to connect to node #{cfg.ctrl_node}"
    end

    supervisor
  end

  @impl true
  def stop(state) do
    Logger.warning("Application #{@app_name} exited. Stopping the system.")
    System.stop
  end
end
