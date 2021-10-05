defmodule DTask.App.TUI do
  @moduledoc false

  use Application
  require Logger

  alias DTask.{App, ResourceUsage, Task}

  @app_name :dtask_tui

  @impl true
  def start(_type, args) do
    cfg = Enum.into(Application.get_all_env(@app_name), %{})

    # Try to start the node
    App.ensure_node_alive(cfg, :tui_node_prefix)

    children_data = [
      %{
        id: Task.Monitor,
        start: {Task.Monitor, :start_link, [
          {Task.Dispatcher, cfg.master_node}
        ]}
      },
      %{
        id: ResourceUsage.Collector,
        start: {ResourceUsage.Collector, :start_link, [
          cfg.resource_report_timeout_millis
        ]}
      }
    ]

    children_tui =
      if Enum.member?(args, :debug_no_tui),
         do: [],
         else: [{
           Ratatouille.Runtime.Supervisor,
           runtime: [
             app: DTask.TUI,
             shutdown: :system
           ]
         }]

    children = children_data ++ children_tui

    # Start supervisor
    opts = [strategy: :one_for_one, name: __MODULE__.Supervisor]
    supervisor = Supervisor.start_link(children, opts)

    # Try connect to master node
    case Node.connect(cfg.master_node) do
      true -> Logger.notice("Connected to master node #{cfg.master_node}")
      _    -> Logger.notice("Failed to connect to master node #{cfg.master_node}")
    end

    supervisor
  end

end
