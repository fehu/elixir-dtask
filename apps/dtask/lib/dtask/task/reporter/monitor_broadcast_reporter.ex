alias DTask.Task.Dispatcher

defmodule DTask.Task.Reporter.MonitorBroadcastReporter do
  @moduledoc """
  Default reporter.

  Casts progress to every `Monitor` registered on cluster.
  """

  @enforce_keys [:task_id]
  defstruct [:task_id]

  @type t :: %__MODULE__{task_id: Dispatcher.task_id}
end

alias DTask.Task.{Monitor, Reporter}
alias DTask.Task.Reporter.MonitorBroadcastReporter

defimpl Reporter, for: MonitorBroadcastReporter do
  @spec progress(MonitorBroadcastReporter.t, term) :: :ok
  def progress(reporter, progress),
      do: Monitor.Broadcast.progress(reporter.task_id, progress)
end

defmodule DTask.Task.Reporter.MonitorBroadcastReporter.Builder do
  @behaviour Reporter.Builder

  @spec new(Dispatcher.server, Dispatcher.task_id) :: MonitorBroadcastReporter.t
  def new(_, task_id), do: %MonitorBroadcastReporter{task_id: task_id}
end
