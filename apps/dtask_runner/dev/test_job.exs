defmodule TestJob do
  def loop(n_max, wait), do: loop(n_max, wait, 0)

  def loop(n_max, wait, n) do
    IO.puts("Working: #{n} / #{n_max}")
    :timer.sleep(wait)

    if :rand.uniform() > 0.98 do
      IO.puts(:standard_error, "FAIL")
      exit({:shutdown, 1})
    end

    if n < n_max,
      do: loop(n_max, wait, n + 1),
      else: IO.puts("DONE")
  end
end

default_steps = 10
default_wait  = 1_000

case System.argv do
  [steps, wait] -> TestJob.loop(String.to_integer(steps), String.to_integer(wait))
  [steps]       -> TestJob.loop(String.to_integer(steps), default_wait)
  []            -> TestJob.loop(default_steps, default_wait)
  _             -> raise "Expected arguments: steps \\ #{default_steps}, wait \\ #{default_wait}"
end
