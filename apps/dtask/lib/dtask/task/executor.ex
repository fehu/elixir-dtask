defmodule DTask.Task.Executor do
  @moduledoc false

  alias DTask.Task
  alias DTask.Task.{Dispatcher, Reporter}

  use GenServer
  require Logger

  @spec start_link(Dispatcher.server, Reporter.Builder.t) :: GenServer.on_start
  def start_link(dispatcher, reporter_builder) do
    Logger.debug("DTask.Task.Executor.start_link(#{inspect(dispatcher)}, #{reporter_builder})")
    GenServer.start_link(__MODULE__, {dispatcher, reporter_builder}, name: __MODULE__)
  end

  # TODO: use `call` to ensure task was accepted for execution
  @spec exec_task(GenServer.server, Task.t, Task.params, Dispatcher.task_id) :: :ok
  def exec_task(server, task, params, task_id) do
    Logger.debug("DTask.Task.Executor.exec_task(#{inspect(server)}, #{inspect(task)}, #{inspect(params)})")
    GenServer.cast(server, {:exec, task, params, task_id})
  end

  # # # Callbacks # # #

  @impl true
  def init(cfg) do
    {:ok, cfg}
  end

  @impl true
  def handle_cast({:exec, task, params, task_id}, cfg={dispatcher, reporter_builder}) do
    Logger.info("Executing task [#{task_id}] #{inspect(task)} with parameters #{inspect(params)}")
    reporter = reporter_builder.new(dispatcher, task_id)
    # Execute the task
    outcome = task.exec(reporter, params)
    Dispatcher.report_finished(dispatcher, task_id, outcome)
    {:noreply, cfg}
  end
end