defmodule DTask.Task.Executor do
  @moduledoc false

  alias DTask.Task

  use GenServer
  require Logger

  @spec start_link(Dispatcher.server) :: GenServer.on_start
  def start_link(dispatcher) do
    Logger.debug("DTask.Task.Executor.start_link")
    GenServer.start_link(__MODULE__, dispatcher, name: __MODULE__)
  end

  @spec exec_task(GenServer.server, Task.t, Task.params) :: :ok
  def exec_task(server, task, params) do
    Logger.debug("DTask.Task.Executor.exec_task(#{inspect(server)}, #{inspect(task)}, #{inspect(params)})")
    GenServer.cast(server, {:exec, task, params})
  end

  # # # Callbacks # # #

  @impl true
  def init(dispatcher) do
    {:ok, dispatcher}
  end

  @impl true
  def handle_cast({:exec, task, params}, dispatcher) do
    Logger.info("Executing task #{inspect(task)} with parameters #{inspect(params)}")
    task.exec(dispatcher, params)
    {:noreply, nil}
  end
end