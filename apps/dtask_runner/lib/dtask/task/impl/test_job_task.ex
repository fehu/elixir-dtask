defmodule DTask.Task.Impl.TestJobTask do
  @moduledoc false

  alias DTask.Task
  alias DTask.Task.{Reporter, ShellCmd}

  @behaviour Task

  @type params :: term

  @spec exec(Reporter.t, params) :: no_return
  def exec(reporter, _params) do
    cmd = "elixir dev/test_job.exs"
    dir = "."
    handle_data = fn
      _, "Working: " <> progress ->
        report = String.trim(progress)
        Reporter.progress(reporter, report)
      _, _ ->
        :do_nothing
    end
    handle_exit = fn
      _, 0 -> {:success, "done"}
      _, c -> {:failure, {:non_zero_exit, c}}
    end
    ShellCmd.exec(cmd, dir, handle_data, handle_exit)
  end

end
