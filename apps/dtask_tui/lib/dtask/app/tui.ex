defmodule DTask.App.TUI do
  @moduledoc false

  use Application
  require Logger

  alias DTask.{App, ResourceUsage, Task}
  alias DTask.TUI.Event.DebouncingEventManager

  @app_name :dtask_tui

  @esc_events_debounce_millis 50

  @impl true
  def start(_type, args) do
    # Disable logger
    Logger.configure(level: :error)

    cfg = Enum.into(Application.get_all_env(@app_name), %{})

    # Try to start the node
    App.ensure_node_alive(cfg, :tui_node_prefix)

    children_data = [
      %{
        id: Task.Monitor,
        start: {Task.Monitor, :start_link, [
          {Task.Dispatcher, cfg.ctrl_node}
        ]}
      },
      %{
        id: ResourceUsage.Collector,
        start: {ResourceUsage.Collector, :start_link, [
          cfg.resource_report_timeout_millis
        ]}
      },
      %{
        id: DebouncingEventManager,
        start: {DebouncingEventManager, :start_link, [
          Ratatouille.EventManager,
          @esc_events_debounce_millis
        ]},
        restart: :transient
      }
    ]

    children_tui =
      if Enum.member?(args, :debug_no_tui),
         do: [],
         else: [
           {Ratatouille.Runtime.Supervisor, [
             name: Ratatouille.Runtime.Supervisor,
             runtime: [
               app: DTask.TUI,
               shutdown: :system,
               event_manager: DebouncingEventManager,
               quit_events: DTask.TUI.quit_events
             ]
           ]}
         ]

    children = children_data ++ children_tui

    # Try connect to master node
    case Node.connect(cfg.ctrl_node) do
      true -> Logger.notice("Connected to control node #{cfg.ctrl_node}")
      _    -> Logger.notice("Failed to connect to master node #{cfg.ctrl_node}")
    end

    # Start supervisor
    opts = [strategy: :one_for_one, name: __MODULE__.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
