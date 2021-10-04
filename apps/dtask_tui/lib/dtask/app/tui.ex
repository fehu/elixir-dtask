defmodule DTask.App.TUI do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # {Ratatouille.Runtime.Supervisor, runtime: [app: Toby.App]},
    ]


#    # Connect to master node
#    case Node.connect(cfg.master_node) do
#      true -> Logger.notice("Connected to master node #{cfg.master_node}")
#      _    -> raise "Failed to connect to node #{cfg.master_node}"
#    end

    opts = [strategy: :one_for_one, name: DTask.App.TUI.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
