defmodule TestJob do
  def loop(n_max, wait), do: loop(n_max, wait, 0)

  def loop(n_max, wait, n) do
    IO.puts("Working: #{n} / #{n_max}")
    :timer.sleep(wait)

    if :rand.uniform() > 0.9 do
      IO.puts(:standard_error, "FAIL")
      exit({:shutdown, 1})
    end

    if n < n_max,
      do: loop(n_max, wait, n + 1),
      else: IO.puts("DONE")
  end
end

TestJob.loop(10, 1_000)
