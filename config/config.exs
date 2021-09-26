import Config

common = [
  exec_node_prefix: "exec",
  ctrl_node_prefix: "ctrl",
  node_cookie: :wnxt6nu1ipeJfRagFcCTyQKc0x3uEhLD
]
config :dtask_controller, common
config :dtask_runner, common


config :dtask_controller,
       resource_report_timeout_millis: 1_500

config :dtask_runner,
#       master_node: :"ctrl@127.0.0.1",
       master_node: :ctrl@opensuse,
       resource_report_interval: 1_000,
       resource_usage: %{
         extractor: DTask.ResourceUsage.Extractor.NvidiaSmi,
         params: nil
       }

config :logger,
       backends: [:console],
       compile_time_purge_matching: [
         [level_lower_than: :info]
       ]
#config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]

import_config "tasks.exs"
import_config "#{config_env()}.exs"
