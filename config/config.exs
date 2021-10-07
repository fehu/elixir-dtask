import Config

cookie = :wnxt6nu1ipeJfRagFcCTyQKc0x3uEhLD
cookie_cfg = [node_cookie: cookie]

config :dtask_controller, cookie_cfg
config :dtask_runner, cookie_cfg
config :dtask_tui, cookie_cfg

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

ctrl_node_prefix = "ctrl"
exec_node_prefix = "exec"
tui_node_prefix  = "user"

master_node = :ctrl@localhost

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

config :dtask_controller,
       ctrl_node_prefix: ctrl_node_prefix,
       exec_node_prefix: exec_node_prefix

config :dtask_runner,
       master_node: master_node,
       exec_node_prefix: exec_node_prefix,
       resource_report_interval: 1_000,
       resource_usage: %{
         extractor: DTask.ResourceUsage.Extractor.Combined,
         params: [
           {DTask.ResourceUsage.Extractor.CpuInfo, :each},
           {DTask.ResourceUsage.Extractor.MemInfo, nil},
           {DTask.ResourceUsage.Extractor.NvidiaSmi, nil}
         ]
       }

config :dtask_tui,
       master_node: master_node,
       tui_node_prefix: tui_node_prefix,
       resource_report_timeout_millis: 1_500,
       resource_usage_hist_limit: 60,
       timezone: "America/Mexico_City"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

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
