# iex --sname runner --cookie 1234 -S mix
# import_file "dev/runner.exs"

Node.connect :ctrl@opensuse

alias DTask.ResourceUsage.Reporter
alias DTask.ResourceUsage.Extractor.NvidiaSmi

collector = {DTask.ResourceUsage.Collector, :ctrl@opensuse}

reporter_pid = Reporter.start_link(collector, 1_000, NvidiaSmi, [], :register)

