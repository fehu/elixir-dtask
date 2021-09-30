alias DTask.Task.{Dispatcher, Reporter}

defmodule DTask.Task.Reporter.DispatcherReporter do
  @moduledoc """
  Default reporter. Sends progress reports back to `Dispatcher`.
  """

  @enforce_keys [:dispatcher, :task]
  defstruct [:dispatcher, :task]

  @type t :: %__MODULE__{dispatcher: GenServer.server, task: Dispatcher.task}
end

alias DTask.Task
alias DTask.Task.Reporter.DispatcherReporter

defimpl DTask.Task.Reporter, for: DispatcherReporter do
  @spec progress(DispatcherReporter.t, term) :: :ok
  def progress(reporter, progress),
      do: Dispatcher.report_progress(reporter.dispatcher, reporter.task, progress)
end

defmodule DTask.Task.Reporter.DispatcherReporter.Builder do
  @behaviour Reporter.Builder

  @spec new(Dispatcher.server, Task.t, Task.params) :: DispatcherReporter.t
  def new(dispatcher, task, params),
      do: %DispatcherReporter{dispatcher: dispatcher, task: {task, params}}
end
