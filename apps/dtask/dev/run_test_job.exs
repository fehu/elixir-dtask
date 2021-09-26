
x = System.cmd("elixir", ["dev/test_job.exs"])

x = System.cmd("elixir", ["dev/test_job.exs"], into: IO.stream())

# x = Port.command()

# port = Port.open({:spawn, "elixir dev/test_job.exs"}, [])

defmodule Test do
  def listen_port(port, timeout) do
    receive do
      {^port, x} ->
        IO.inspect(x)
        listen_port(port, timeout)
      #      {^port, {:data, data}} ->
      #        IO.puts("DATA begin")
      #        IO.inspect(data)
      #        IO.puts("DATA end")
      #        listen_port(port, timeout)
      #      {^port, other} ->
      #        IO.puts("OTHER:")
      #        IO.inspect(other)
      #        listen_port(port, timeout)
    after
      timeout -> IO.puts("timeout!")
    end
  end
end
#defmodule Test do
#  def listen_port(port, timeout) do
#    if Port.info(port) do
#      receive do
#        {^port, x} ->
#          IO.inspect(x)
#          listen_port(port, timeout)
#        #      {^port, {:data, data}} ->
#        #        IO.puts("DATA begin")
#        #        IO.inspect(data)
#        #        IO.puts("DATA end")
#        #        listen_port(port, timeout)
#        #      {^port, other} ->
#        #        IO.puts("OTHER:")
#        #        IO.inspect(other)
#        #        listen_port(port, timeout)
#      after
#        timeout -> IO.puts("timeout!")
#      end
#    end
#  end
#end

port = Port.open(
  {:spawn, "pipenv run python run_train.opus_2016_es.py"},
  [
    {:cd, "/home/fehu/dev/python/bert-test/spanberta/"},
    :exit_status
  ]
)
port = Port.open({:spawn, "elixir dev/test_job.exs"}, [])

Test.listen_port(port, 2_000)
