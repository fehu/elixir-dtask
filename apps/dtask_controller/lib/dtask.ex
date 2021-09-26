defmodule DTask do
  @moduledoc false

  use DTask.Task.Dispatcher.CLI
  use DTask.ResourceUsage.Collector.CLI
end
