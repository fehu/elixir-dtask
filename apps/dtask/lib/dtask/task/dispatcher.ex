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

  @type task_descriptor :: {Task.t, Task.params}
  @type task_id :: non_neg_integer

  @typep task_pending  :: {task_descriptor, task_id}
  @typep task_running  :: {task_id, %{
                                      node: node,
                                      descriptor: task_descriptor,
                                      progress: term,
                                      dispatched: DateTime
                                    }
                          }
  @typep task_finished :: {task_id, %{
                                      node: node,
                                      descriptor: task_descriptor,
                                      outcome: {:success, term} | {:failure, term},
                                      dispatched: DateTime,
                                      finished: DateTime
                                    }
                          }
  @type tasks_state :: %{
                         pending: [task_pending],
                         running: [task_running],
                         finished: [task_finished]
                       }

  @typep state :: %{
                    finished?: boolean,
                    tasks: tasks_state,
                    executors: executors_state,
                    exec_node_prefix: String.t,
                    next_task_id: non_neg_integer
                  }

  @spec start_link(String.t, [task_descriptor, ...]) :: GenServer.on_start
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

  @spec get_pending(server) :: [task_descriptor]
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

  @spec add_task(server, Task.t, Task.params) :: :ok
  def add_task(server \\ __MODULE__, task, params) do
    GenServer.cast(server, {:add_tasks, [{task, params}]})
  end

  @spec add_tasks(server, [task_descriptor, ...]) :: :ok
  def add_tasks(server \\ __MODULE__, tasks) do
    GenServer.cast(server, {:add_tasks, tasks})
  end

  # Execution notifications (used by `DTask.Task.Executor`)

  @spec report_progress(server, task_id, term) :: :ok
  def report_progress(server, task_id, progress) do
    Logger.debug("DTask.Task.Dispatcher.report_progress(#{inspect(server)}, #{task_id}, #{inspect(progress)})")
    GenServer.cast(server, {:progress, task_id, progress})
  end

  @spec report_finished(server, task_id, Task.outcome) :: :ok
  def report_finished(server, task_id, outcome) do
    Logger.debug("DTask.Task.Dispatcher.report_finished(#{inspect(server)}, #{task_id}, #{inspect(outcome)})")
    GenServer.cast(server, {:finished, task_id, outcome})
  end

  # # # Callbacks # # #

  @impl true
  def init({exec_node_prefix, tasks}) do
    executors = Node.list() |> Enum.filter(&executor_node?(exec_node_prefix, &1))
    Logger.notice("Available executors: #{inspect(executors)}")
    state = %{
      finished?: false,
      tasks: %{
        pending: Enum.with_index(tasks),
        running: [],
        finished: []
      },
      executors: %{
        idle: executors,
        busy: []
      },
      exec_node_prefix: exec_node_prefix,
      next_task_id: length(tasks)
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
      {[{task, task_id} | pending], [node | idle]} ->
        # Dispatch next `task` on idle `node` executor
        dispatch_task(task, node, task_id)
        running = %{
          progress: :dispatched,
          node: node,
          descriptor: task,
          dispatched: DateTime.utc_now()
        }
        new_state = state |> put_in([:tasks, :pending], pending)
                          |> put_in([:executors, :idle], idle)
                          |> update_in([:tasks, :running], &[{task_id, running} | &1])
                          |> update_in([:executors, :busy], &[node | &1])
                          |> Map.put(:finished?, false)
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
    {next_id, new_state0} = Map.get_and_update(state, :next_task_id, &{&1, &1 + length(tasks)})
    new_tasks = Stream.with_index(tasks)
             |> Stream.map(fn {task, i} -> {task, next_id + i} end)
             |> Enum.to_list
    new_state = update_in(new_state0.tasks.pending, &Enum.concat(&1, new_tasks))
    {:noreply, new_state, {:continue, :dispatch_next}}
  end

  # Execution callbacks (used by `DTask.Task.Executor`)

  @impl true
  def handle_cast({:progress, task_id, progress}, state) do
    Logger.debug("DTask.Task.Dispatcher.handle_cast {:progress, #{task_id}, #{inspect(progress)}}")
    new_state = update_in(
      state.tasks.running,
      &keyupdate(&1, task_id, 0, fn {_, m} -> {task_id, %{m | :progress => progress}} end)
    )
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:finished, task_id, outcome}, state) do
    Logger.info("Finished task [#{task_id}] with outcome #{inspect(outcome)}")
    {node, new_state0} = task_finished_upd(state, task_id, outcome)
    new_state = new_state0 |> update_in([:executors, :busy], &List.delete(&1, node))
                           |> update_in([:executors, :idle], &[node | &1])
    {:noreply, new_state, {:continue, :dispatch_next}}
  end

  # Private functions

  defp executor_node?(exec_node_prefix, node) do
    String.starts_with?(Atom.to_string(node), exec_node_prefix <> "@")
  end

  @spec dispatch_task(task_descriptor, node, task_id) :: :ok
  defp dispatch_task({task, params}, node, task_id) do
    server = {DTask.Task.Executor, node}
    Logger.info("Dispatching on node #{inspect(server)}" <>
                " task [#{task_id}] #{inspect(task)} with parameters: #{inspect(params)}")
    Executor.exec_task(server, task, params, task_id)
  end

  @spec task_finished_upd(state, task_id, Task.outcome) :: {node, state}
  defp task_finished_upd(state, task_id, outcome) do
    {{_, running}, new_state0} = get_and_update_in(
      state.tasks.running,
      &{List.keyfind(&1, task_id, 0), List.keydelete(&1, task_id, 0)}
    )
    finished = %{
      node: running.node,
      descriptor: running.descriptor,
      outcome: outcome,
      dispatched: running.dispatched,
      finished: DateTime.utc_now()
    }
    new_state = update_in(new_state0.tasks.finished, &[{task_id, finished} | &1])
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
      defdelegate add_task(task, params), to: Dispatcher
      defdelegate add_tasks(tasks),       to: Dispatcher

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
