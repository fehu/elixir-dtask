alias DTask.Task.{Dispatcher, Reporter}

defmodule DTask.Task.Reporter.DispatcherReporter do
  @moduledoc """
  Default reporter. Sends progress reports back to `Dispatcher`.
  """

  @enforce_keys [:dispatcher, :task_id]
  defstruct [:dispatcher, :task_id]

  @type t :: %__MODULE__{dispatcher: GenServer.server, task_id: Dispatcher.task_id}
end

alias DTask.Task.Reporter.DispatcherReporter

defimpl DTask.Task.Reporter, for: DispatcherReporter do
  @spec progress(DispatcherReporter.t, term) :: :ok
  def progress(reporter, progress),
      do: Dispatcher.report_progress(reporter.dispatcher, reporter.task_id, progress)
end

defmodule DTask.Task.Reporter.DispatcherReporter.Builder do
  @behaviour Reporter.Builder

  @spec new(Dispatcher.server, Dispatcher.task_id) :: DispatcherReporter.t
  def new(dispatcher, task_id),
      do: %DispatcherReporter{dispatcher: dispatcher, task_id: task_id}
end
