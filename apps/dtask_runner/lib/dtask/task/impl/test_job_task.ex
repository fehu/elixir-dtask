defmodule DTask.Task.Impl.TestJobTask do
  @moduledoc false

  alias DTask.Task
  alias DTask.Task.{Reporter, ShellCmd}
  alias DTask.Task.DTO.Progress

  @behaviour Task

  @type params :: term

  @regex ~r"^\s*(.*): (\d+) / (\d+)\s*$"
  @spec exec(Reporter.t, params) :: no_return
  def exec(reporter, _params) do
    cmd = "elixir dev/test_job.exs"
    dir = "."
    handle_data = fn
      _, data ->
        case Regex.run(@regex, data) do
          [_, label, step, total] ->
            Reporter.progress(reporter, Progress.new(label, step, total))
          _ -> nil
        end
    end
    handle_exit = fn
      _, 0 -> {:success, "done"}
      _, c -> {:failure, {:non_zero_exit, c}}
    end
    ShellCmd.exec(cmd, dir, handle_data, handle_exit)
  end

end
