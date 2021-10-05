defmodule DTask.TUI.Update do
  @moduledoc false

  alias DTask.{ResourceUsage, Task}

  alias Ratatouille.Runtime.Command

  @typep data :: :tasks
               | :resource_usage

  @spec request_refresh(data) :: Command.t
  def request_refresh(:tasks) do
    Command.new &Task.Monitor.get_state/0,
                {:refreshed, :tasks}
  end

  def request_refresh(:resource_usage) do
    Command.new &ResourceUsage.Collector.get_usage/0,
                {:refreshed, :resource_usage}
  end

end
