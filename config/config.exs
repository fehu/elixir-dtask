import Config

ctrl_node_prefix = "ctrl"
exec_node_prefix = "exec"
tui_node_prefix  = "tui"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

config :dtask_controller,
       ctrl_node_prefix: ctrl_node_prefix,
       exec_node_prefix: exec_node_prefix

config :dtask_runner,
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
       tui_node_prefix: tui_node_prefix,
       resource_report_timeout_millis: 1_500,
       resource_usage_hist_limit: 60,
       timezone: "America/Mexico_City"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

import_config "#{config_env()}.exs"
