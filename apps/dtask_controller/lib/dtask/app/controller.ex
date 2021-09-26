defmodule DTask.App.Controller do
  @moduledoc """
  Cluster controller (master) application.

  Children:
    * Task dispatcher (`DTask.Task.Dispatcher`)
    * Resource usage collector (`DTask.ResourceUsage.Collector`)

  """
  use Application

  Application.ensure_started(:logger)

  alias DTask.App
  alias DTask.ResourceUsage.Collector
  alias DTask.Task.Dispatcher

  @app_name :dtask_controller

  @type config :: %{
                    ctrl_node_prefix: String.t,
                    exec_node_prefix: String.t,
                    resource_report_timeout_millis: non_neg_integer,
                    tasks: [Dispatcher.task, ...]
                  }

  @impl true
  def start(_type, _args) do
    cfg = Enum.into(Application.get_all_env(@app_name), %{})

    # Ensure node started
    App.ensure_node_alive!(cfg, :ctrl_node_prefix)

    children = [
      %{
        id: Dispatcher,
        start: {Dispatcher, :start_link, [cfg.exec_node_prefix, cfg.tasks]}
      },
      %{
        id: Collector,
        start: {Collector, :start_link, [cfg.resource_report_timeout_millis]}
      }
    ]
    opts = [strategy: :one_for_one, name: __MODULE__.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
