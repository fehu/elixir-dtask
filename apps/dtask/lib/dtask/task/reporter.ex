defprotocol DTask.Task.Reporter do
  @moduledoc false

  @spec progress(t, term) :: :ok
  def progress(reporter, progress)

end

defmodule DTask.Task.Reporter.Builder do
  @moduledoc false

  @type t :: module

  alias DTask.Task
  alias DTask.Task.{Dispatcher, Reporter}

  @callback new(Dispatcher.server, Task.t, Task.params) :: Reporter.t
end
