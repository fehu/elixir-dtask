defmodule DTask.Task.Impl.TestJobTask do
  @moduledoc false

  alias DTask.Task
  alias DTask.Task.{Dispatcher, ShellCmd}

  @behaviour Task

  @type params :: term

  @spec exec(Dispatcher.server, params) :: no_return
  def exec(dispatcher, params) do
    task = {__MODULE__, params}
    cmd = "elixir dev/test_job.exs"
    dir = "."
    handle_data = fn
      "Working: " <> progress -> Dispatcher.report_progress(dispatcher, task, progress)
      _                       -> :do_nothing
    end
    handle_exit = fn
      0 -> Dispatcher.report_success(dispatcher, task, "done")
      c -> Dispatcher.report_failure(dispatcher, task, {:non_zero_exit, c})
    end
    ShellCmd.exec(cmd, dir, handle_data, handle_exit)
  end

end
