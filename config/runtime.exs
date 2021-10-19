import Config

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

Code.require_file("./config/runtime/cluster.exs")

config :dtask_runner,
       ctrl_node: Cluster.ctrl_node

config :dtask_tui,
       ctrl_node: Cluster.ctrl_node

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

Code.require_file("./config/runtime/tasks.exs")

config :dtask_controller,
       tasks: Tasks.get

config :dtask_runner,
       tasks_local_config: Tasks.local_config
