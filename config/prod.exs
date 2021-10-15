import Config

config :logger, :console,
       level: :info,
       format: "$date $time [$level]  $message\n",
       # format: "$date $time [$level]  $message | $metadata\n",
       # metadata: [:mfa, :file, :line, :registered_name, :initial_call],
       compile_time_purge_matching: [
         [level_lower_than: :info]
       ]
