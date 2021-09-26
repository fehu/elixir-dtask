# iex --sname ctrl --cookie 1234 -S mix
# import_file "dev/ctrl.exs"

alias DTask.ResourceUsage.Collector

{:ok, collector_pid} = Collector.start_link(2_000)

get_usage = fn -> Collector.get_usage collector_pid end


# elixir --sname ctrl -S mix cmd --app dtask_controller mix run --no-halt
