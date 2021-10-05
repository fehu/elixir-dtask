import Config

config :logger,
       compile_time_purge_matching: [
         [module: DTask.ResourceUsage.Collector.Broadcast, level_lower_than: :error],
         [module: DTask.ResourceUsage.Collector, level_lower_than: :error],
         [module: DTask.ResourceUsage.Reporter, level_lower_than: :error]
       ]
