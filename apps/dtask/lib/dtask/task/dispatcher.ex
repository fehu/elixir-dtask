defmodule DTask.Task.Dispatcher do
  @moduledoc """
  Dispatches Tasks to available Executors.
  Keeps track of Task execution state (progress & result).
  """

  alias DTask.Task
  alias DTask.Task.Executor

  use GenServer
  require Logger

  @type server :: GenServer.server

  @type executors_state :: %{
    idle: [node],
    busy: [node]
  }

  @type task :: {Task.t, Task.params}
  @typep task_running :: {task, %{node: node, progress: term}}
  @typep task_finished :: {task, {:success | :failure, term}}
  @type tasks_state :: %{
                         pending: [task],
                         running: [task_running],
                         finished: [task_finished]
                       }

  @spec start_link(String.t, [task, ...]) :: GenServer.on_start
  def start_link(exec_node_prefix, tasks) do
    Logger.debug("DTask.Task.Dispatcher.start_link(#{exec_node_prefix}, #{inspect(tasks)})")
    GenServer.start_link(__MODULE__, {exec_node_prefix, tasks}, name: __MODULE__)
  end

  # Queries

  @spec get_executors(server) :: executors_state
  def get_executors(server \\ __MODULE__) do
    GenServer.call(server, :executors)
  end

  @spec finished?(server) :: boolean
  def finished?(server \\ __MODULE__) do
    GenServer.call(server, :finished?)
  end

  @spec get_tasks(server) :: tasks_state
  def get_tasks(server \\ __MODULE__) do
    GenServer.call(server, :tasks)
  end

  @spec get_pending(server) :: [task]
  def get_pending(server \\ __MODULE__) do
    GenServer.call(server, :pending)
  end

  @spec get_running(server) :: [task_running]
  def get_running(server \\ __MODULE__) do
    GenServer.call(server, :running)
  end

  @spec get_finished(server) :: [task_finished]
  def get_finished(server \\ __MODULE__) do
    GenServer.call(server, :finished)
  end

  # Commands

  @spec add_task(server, task) :: :ok
  def add_task(server \\ __MODULE__, task) do
    GenServer.cast(server, {:add_tasks, [task]})
  end

  @spec add_tasks(server, [task, ...]) :: :ok
  def add_tasks(server \\ __MODULE__, tasks) do
    GenServer.cast(server, {:add_tasks, tasks})
  end

  # Execution notifications (used by `DTask.Task.Executor`)

  @spec report_progress(server, task, term) :: :ok
  def report_progress(server, task, progress) do
    Logger.debug("DTask.Task.Dispatcher.report_progress(#{inspect(server)}, #{inspect(task)}, #{inspect(progress)})")
    GenServer.cast(server, {:progress, task, progress})
  end

  @spec report_success(server, task, term) :: :ok
  def report_success(server, task, result) do
    Logger.debug("DTask.Task.Dispatcher.report_success(#{inspect(server)}, #{inspect(task)}, #{inspect(result)})")
    GenServer.cast(server, {:success, task, result})
  end

  @spec report_failure(server, task, term) :: :ok
  def report_failure(server, task, error) do
    Logger.debug("DTask.Task.Dispatcher.report_failure(#{inspect(server)}, #{inspect(task)}, #{inspect(error)})")
    GenServer.cast(server, {:failure, task, error})
  end

  # # # Callbacks # # #

  @impl true
  def init({exec_node_prefix, tasks}) do
    executors = Node.list() |> Enum.filter(&executor_node?(exec_node_prefix, &1))
    Logger.notice("Available executors: #{inspect(executors)}")
    state = %{
      finished?: false,
      tasks: %{
        pending: tasks,
        running: [],
        finished: []
      },
      executors: %{
        idle: executors,
        busy: []
      },
      exec_node_prefix: exec_node_prefix
    }

    # Monitor :nodeup/:nodedown events
    :net_kernel.monitor_nodes(true)

    {:ok, state, {:continue, :dispatch_next}}
  end

  # Tasks state queries

  @impl true
  def handle_call(:executors, _from, state) do
    {:reply, state.executors, state}
  end

  @impl true
  def handle_call(:finished?, _from, state) do
    {:reply, state.finished?, state}
  end

  @impl true
  def handle_call(:tasks, _from, state) do
    {:reply, state.tasks, state}
  end

  @impl true
  def handle_call(:pending, _from, state) do
    {:reply, state.tasks.pending, state}
  end

  @impl true
  def handle_call(:running, _from, state) do
    {:reply, state.tasks.running, state}
  end

  @impl true
  def handle_call(:finished, _from, state) do
    {:reply, state.tasks.finished, state}
  end

  # Task dispatch

  @impl true
  def handle_continue(:dispatch_next, state) do
    Logger.debug(["DTask.Task.Dispatcher.handle_continue(:dispatch_next, #{inspect(state)})"])
    case {state.tasks.pending, state.executors.idle} do
      {[], _} ->
        if Enum.empty?(state.tasks.running) do
          Logger.notice("Finished executing all tasks")
          new_state = %{state | :finished? => true}
          {:noreply, new_state}
        else
          {:noreply, state}
        end
      {[next | pending], [node | idle]} ->
        dispatch_task(next, node)
        running = {next, %{progress: :dispatched, node: node}}
        new_state = state |> put_in([:tasks, :pending], pending)
                          |> put_in([:executors, :idle], idle)
                          |> update_in([:tasks, :running], &[running | &1])
                          |> update_in([:executors, :busy], &[node | &1])
        {:noreply, new_state}
      {_, []} ->
        {:noreply, state}
    end
  end

  # Nodes discovery

  @impl true
  def handle_info({:nodeup, node}, state) do
    if executor_node?(state.exec_node_prefix, node) do
      Logger.notice("New executor node discovered: #{node}")
      new_state = update_in(state.executors.idle, &[node | &1])
      {:noreply, new_state, {:continue, :dispatch_next}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    if executor_node?(state.exec_node_prefix, node) do
      Logger.warning("Lost connection to executor: #{node}")
      task0 = Enum.find(state.tasks.running, fn {_, v} -> v.node == node end)
      {_, new_state0} =
        if task0 do
          task_finished_upd(state, elem(task0, 0), {:error, :nodedown})
        else
          {nil, state}
        end
      new_state = new_state0 |> update_in([:executors, :busy], &List.delete(&1, node))
                             |> update_in([:executors, :idle], &List.delete(&1, node))
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  # Commands

  @impl true
  def handle_cast({:add_tasks, tasks}, state) do
    new_state = update_in(state.tasks.pending, &Enum.concat(&1, tasks))
    {:noreply, new_state, {:continue, :dispatch_next}}
  end

  # Execution callbacks (used by `DTask.Task.Executor`)

  @impl true
  def handle_cast({:progress, task, progress}, state) do
    Logger.debug("DTask.Task.Dispatcher.handle_cast {:progress, #{inspect(task)}, #{inspect(progress)}}")
    new_state = update_in state.tasks.running,
                          &keyupdate(&1, task, 0, fn {_, m} -> {task, %{m | :progress => progress}} end)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:success, task, result}, state) do
    Logger.debug("DTask.Task.Dispatcher.handle_cast {:success, #{inspect(task)}, #{inspect(result)}}")
    task_finished(state, task, {:success, result})
  end

  @impl true
  def handle_cast({:failure, task, error}, state) do
    Logger.debug("DTask.Task.Dispatcher.handle_cast {:failure, #{inspect(task)}, #{inspect(error)}}")
    task_finished(state, task, {:failure, error})
  end

  # Private functions

  defp executor_node?(exec_node_prefix, node) do
    String.starts_with?(Atom.to_string(node), exec_node_prefix <> "@")
  end

  defp dispatch_task({task, params}, node) do
    server = {DTask.Task.Executor, node}
    Logger.info("Dispatching on node #{inspect(server)} task #{inspect(task)} with parameters: #{inspect(params)}")
    Executor.exec_task(server, task, params)
  end

  defp task_finished(state, task, outcome) do
    Logger.info("Finished task #{inspect(task)} with outcome #{inspect(outcome)}")
    {node, new_state0} = task_finished_upd(state, task, outcome)
    new_state = new_state0 |> update_in([:executors, :busy], &List.delete(&1, node))
                           |> update_in([:executors, :idle], &[node | &1])
    {:noreply, new_state, {:continue, :dispatch_next}}
  end

  defp task_finished_upd(state, task, outcome) do
    {{_, running}, new_state} =
      state |> update_in([:tasks, :finished], &[{task, outcome} | &1])
            |> get_and_update_in([:tasks, :running], &{List.keyfind(&1, task, 0), List.keydelete(&1, task, 0)})
    {running.node, new_state}
  end

  @spec keyupdate([tuple], any, non_neg_integer, (tuple -> tuple)) :: [tuple]
  defp keyupdate(list, key, position, update) do
    found = List.keyfind(list, key, position)
    List.keyreplace(list, key, position, update.(found))
  end
end

defmodule DTask.Task.Dispatcher.CLI do
  defmacro __using__(_) do
    quote do
      alias DTask.Task.Dispatcher

      # Commands
      defdelegate add_task(task),   to: Dispatcher
      defdelegate add_tasks(tasks), to: Dispatcher

      # Queries
      defdelegate executors(), to: Dispatcher, as: :get_executors
      defdelegate finished?(), to: Dispatcher, as: :finished?
      defdelegate tasks(),     to: Dispatcher, as: :get_tasks
      defdelegate tasks_pending(),   to: Dispatcher, as: :get_pending
      defdelegate tasks_running(),   to: Dispatcher, as: :get_running
      defdelegate tasks_finished(),  to: Dispatcher, as: :get_finished
    end
  end
end
