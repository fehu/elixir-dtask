defmodule DTask.Task.Dispatcher do
  @moduledoc false

  alias DTask.Task
  alias DTask.Task.Executor

  use GenServer
  require Logger

  @type server :: GenServer.server
  @type task :: {Task.t, Task.params}
  @type tasks_state :: %{
                         pending: [task],
                         wip: [{task, %{node: node, progress: term}}],
                         finished: [{task, {:success | :failure, term}}]
                       }

  @spec start_link(String.t, [task, ...]) :: GenServer.on_start
  def start_link(exec_node_prefix, tasks) do
    Logger.debug("DTask.Task.Dispatcher.start_link")
    GenServer.start_link(__MODULE__, {exec_node_prefix, tasks}, name: __MODULE__)
  end

  # Queries

  @spec get_tasks_state(server) :: tasks_state
  def get_tasks_state(server \\ __MODULE__) do
    GenServer.call(server, :tasks_state)
  end

  # Execution notifications (used by `DTask.Task.Executor`)

  @spec report_progress(server, task, term) :: :ok
  def report_progress(server, task, progress) do
    Logger.debug("DTask.Task.Dispatcher.report_progress")
    GenServer.cast(server, {:progress, task, progress})
  end

  @spec report_success(server, task, term) :: :ok
  def report_success(server, task, result) do
    Logger.debug("DTask.Task.Dispatcher.report_success")
    GenServer.cast(server, {:success, task, result})
  end

  @spec report_failure(server, task, term) :: :ok
  def report_failure(server, task, error) do
    Logger.debug("DTask.Task.Dispatcher.report_failure")
    GenServer.cast(server, {:failure, task, error})
  end

  # # # Callbacks # # #

  @impl true
  def init({exec_node_prefix, tasks}) do
    executors = Node.list() |> Enum.filter(&executor_node?(exec_node_prefix, &1))
    Logger.notice("Discovered executors: #{executors}")
    state = %{
      tasks: %{
        pending: tasks,
        wip: [],
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

    {:ok, state}
  end

  # Tasks state queries

  @impl true
  def handle_call(:tasks_state, _from, state) do
    {:reply, state.tasks, state}
  end

  # Task dispatch

  @impl true
  def handle_info(:next, state) do
    Logger.debug("DTask.Task.Dispatcher.handle_info :next")
    new_state =
      case {state.tasks.pending, state.executors.idle} do
        {[], _} ->
          state
        {[next | pending], [node | idle]} ->
          dispatch_task(next, node)
          wip = {next, %{state: :dispatched, node: node}}
          state |> put_in([:tasks, :pending], pending)
                |> put_in([:executors, :idle], idle)
                |> update_in([:tasks, :wip], &[wip | &1])
                |> update_in([:executors, :busy], &[node | &1])
      end
    {:noreply, new_state}
  end

  # Nodes discovery

  @impl true
  def handle_info({:nodeup, node}, state) do
    {added, new_state} = if executor_node?(state.exec_node_prefix, node) do
                            Logger.notice("New executor node discovered: #{node}")
                            {true, update_in(state.executors.idle, &[node | &1])}
                         else
                           {false, state}
                         end
    if added, do: dispatch_next()
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    Logger.warning("Lost connection to executor: #{node}")
    task0 = Enum.find(state.tasks.wip, fn {_, v} -> v.node == node end)
    {_, new_state0} =
      if task0 do
        task_finished_upd(state, elem(task0, 0), {:error, :nodedown})
      else
        {nil, state}
      end
    new_state = new_state0 |> update_in([:executors, :busy], &List.delete(&1, node))
                           |> update_in([:executors, :idle], &List.delete(&1, node))
    {:noreply, new_state}
  end

  # Execution callbacks (used by `DTask.Task.Executor`)

  @impl true
  def handle_cast({:progress, task, progress}, state) do
    new_state = put_in(state.tasks.wip[task].progress, progress)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:success, task, result}, state) do
    task_finished(state, task, {:success, result})
  end

  @impl true
  def handle_cast({:failure, task, error}, state) do
    task_finished(state, task, {:failure, error})
  end

  # Private functions

  defp executor_node?(exec_node_prefix, node) do
    String.starts_with?(Atom.to_string(node), exec_node_prefix <> "@")
  end

  defp dispatch_next(), do: send(self(), :next)

  defp dispatch_task({task, params}, node) do
    server = {DTask.Task.Executor, node}
    Logger.info("Dispatching on node #{inspect(server)} task #{task} with parameters: #{inspect(params)}")
    Executor.exec_task(server, task, params)
  end

  defp task_finished(state, task, outcome) do
    Logger.info("Finished task #{inspect(task)} with outcome #{inspect(outcome)}")
    {node, new_state0} = task_finished_upd(state, task, outcome)
    new_state = new_state0 |> update_in([:executors, :busy], &List.delete(&1, node))
                           |> update_in([:executors, :idle], &[node | &1])
    dispatch_next()
    {:noreply, new_state}
  end

  defp task_finished_upd(state, task, outcome) do
    {{_, wip}, new_state} =
      state |> update_in([:tasks, :finished], &[{task, outcome} | &1])
            |> get_and_update_in([:tasks, :wip], &{List.keyfind(&1, task, 0), List.keydelete(&1, task, 0)})
    {wip.node, new_state}
  end
end
