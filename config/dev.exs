import Config

cookie = :"1234"
cookie_cfg = [node_cookie: cookie]

config :dtask_controller, cookie_cfg
config :dtask_runner, cookie_cfg
config :dtask_tui, cookie_cfg

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

config :logger,
       compile_time_purge_matching: [
         [module: DTask.ResourceUsage.Collector.Broadcast, level_lower_than: :error],
         [module: DTask.ResourceUsage.Collector, level_lower_than: :error],
         [module: DTask.ResourceUsage.Reporter, level_lower_than: :error]
       ]
