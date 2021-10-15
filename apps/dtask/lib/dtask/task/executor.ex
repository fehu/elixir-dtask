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
  def init(cfg={dispatcher, _}) do
    # Monitor `dispatcher` process
    Process.monitor(dispatcher)

    {:ok, cfg}
  end

  @impl true
  def handle_cast({:exec, task, params, task_id}, cfg={dispatcher, reporter_builder}) do
    Logger.info("Executing task [#{task_id}] #{inspect(task)} with parameters #{inspect(params)}")
    reporter = reporter_builder.new(dispatcher, task_id)
    # Start executing the task
    e_task = Elixir.Task.async(__MODULE__, :safe_apply, [task, :exec, [reporter, params]])
    # Block the executor indefinitely
    outcome = case Elixir.Task.await(e_task) do
      {:ok, res} -> res
      error      -> {:failure, error}
    end
    Dispatcher.report_finished(dispatcher, task_id, outcome)
    {:noreply, cfg}
  end

  @impl true
  def handle_info({:DOWN, _, :process, process, reason}, cfg={dispatcher, _}) do
    case process do
      ^dispatcher -> {:stop, {:dispatcher_down, reason}, cfg}
      _           -> {:noreply, cfg}
    end
  end

  @impl true
  def handle_info(other, cfg) do
    Logger.info("Unhandled info message: #{inspect other}")
    {:noreply, cfg}
  end

  @spec safe_apply(module, atom, [term]) :: {:ok, term} | {:error, term} | {:exit, term}
  def safe_apply(m, f, a) do
    try do
      {:ok, apply(m, f, a)}
    catch
      :error, e -> {:error, e, __STACKTRACE__}
      :exit,  e -> {:exit,  e, __STACKTRACE__}
    end
  end
end