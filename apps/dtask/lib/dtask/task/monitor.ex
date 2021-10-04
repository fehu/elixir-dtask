defmodule DTask.Task.Monitor do
  @moduledoc false

  alias DTask.Task
  alias DTask.Task.Dispatcher

  use GenServer
  require Logger

  @typep task_running  :: %{
                            node: node,
                            progress: term,
                            dispatched: DateTime
                          }
  @typep task_finished :: %{
                            node: node,
                            outcome: {:success, term} | {:failure, term},
                            dispatched: DateTime,
                            finished: DateTime
                          }
  @typep task_state :: :pending
                     | {:running, task_running}
                     | {:finished, task_finished}
  @type state :: %{
                   def_of: %{Dispatcher.task_id => Dispatcher.task_descriptor},
                   state_of: %{Dispatcher.task_id => task_state}
                 }

  @spec start_link(Dispatcher.server | nil) :: GenServer.on_start
  def start_link(dispatcher) do
    Logger.debug("DTask.Task.Monitor.start_link(#{inspect(dispatcher)})")
    GenServer.start_link(__MODULE__, dispatcher, name: __MODULE__)
  end

  @spec connect(GenServer.server, Dispatcher.server) :: boolean
  def connect(server \\ __MODULE__, dispatcher) do
    Logger.debug("DTask.Task.Monitor.connect(#{inspect(server)}, #{inspect(dispatcher)})")
    if dispatcher,
       do: GenServer.call(server, {:connect, dispatcher}),
       else: false
  end

  @spec get_state(GenServer.server) :: state | nil
  def get_state(server \\ __MODULE__) do
    GenServer.call(server, :get_state)
  end

  # # # Callbacks # # #

  @impl true
  def init(dispatcher) do
    tasks = if dispatcher, do: fetch_tasks(dispatcher)
    {:ok, tasks}
  end

  @impl true
  def handle_call(:get_state, _, state),
      do: {:reply, state, state}

  @impl true
  def handle_call({:connect, dispatcher}, _, state) do
    tasks = if dispatcher, do: fetch_tasks(dispatcher)
    {:reply, not is_nil(tasks), tasks}
  end

  # Execution reports callbacks

  @impl true
  def handle_cast({:registered, task={task_descriptor, task_id}}, state) when not is_nil(state) do
    Logger.debug("DTask.Task.Monitor.handle_cast {:registered, #{inspect(task)}}")
    new_state = state |> put_in([:def_of, task_id], task_descriptor)
                      |> put_in([:state_of, task_id], :pending)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:dispatched, task_id, timestamp, node}, state) when not is_nil(state) do
    Logger.debug("DTask.Task.Monitor.handle_cast {:dispatched, #{task_id}, #{timestamp}, #{node}}")
    new_state = put_in(
      state.state_of[task_id],
      {:running, %{
        node: node,
        progress: :unknown,
        dispatched: timestamp
      }}
    )
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:progress, task_id, progress}, state) when not is_nil(state) do
    Logger.debug("DTask.Task.Monitor.handle_cast {:progress, #{task_id}, #{inspect(progress)}}")
    new_state = update_in(
      state.state_of[task_id],
      fn
        {:running, s} ->
          {:running, Map.put(s, :progress, progress)}
        other ->
          Logger.warning("Progress was reported for task #{task_id}, that is not :running, but #{other}")
          other
      end
    )
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:finished, task_id, timestamp, outcome}, state) when not is_nil(state) do
    Logger.debug("DTask.Task.Monitor.handle_cast {:finished, #{task_id}, #{timestamp}, #{inspect(outcome)}}")
    new_state = update_in(
      state.state_of[task_id],
      fn
        {:running, s} ->
          {:finished, %{
            node: s.node,
            outcome: outcome,
            dispatched: s.dispatched,
            finished: timestamp
          }}
        other ->
          Logger.warning("Termination was reported for task #{task_id}, that is not :running, but #{inspect(other)}")
          other
      end
    )
    {:noreply, new_state}
  end

  # # # Private functions # # #

  @spec fetch_tasks(Dispatcher.server) :: state | nil
  defp fetch_tasks(dispatcher) do
    tasks = try_fetch_tasks(dispatcher)
    if tasks, do: build_initial_state(tasks)
  end

  @spec try_fetch_tasks(Dispatcher.server) :: Dispatcher.tasks_state | nil
  defp try_fetch_tasks(dispatcher) do
    try do
      Dispatcher.get_tasks(dispatcher)
    catch
      :exit, _ -> nil
    end
  end

  @spec build_initial_state(Dispatcher.tasks_state) :: state
  defp build_initial_state(tasks) do
    def_of_pending =
      for {td, id} <- tasks.pending,
          into: %{} do
        {id, td}
      end
    def_of_all =
      for {id, t} <- tasks.running ++ tasks.finished,
          into: def_of_pending do
        {id, t.descriptor}
      end

    state_of_pending =
      for {_, id} <- tasks.pending,
          into: %{} do
        {id, :pending}
      end
    state_of_pending_running =
      for {id, t} <- tasks.running,
          into: state_of_pending do
        {id, {:running, %{
          node: t.node,
          dispatched: t.dispatched,
          progress: :unknown
        }}}
      end
    state_of_all =
      for {id, t} <- tasks.finished,
          into: state_of_pending_running do
        {id, {:finished, %{
          node: t.node,
          outcome: t.outcome,
          dispatched: t.dispatched,
          finished: t.dispatched
        }}}
      end

    %{
      def_of: def_of_all,
      state_of: state_of_all
    }
  end

  # # # Notifications # # #

  defmodule Broadcast do
    @monitor DTask.Task.Monitor

    @spec registered(Dispatcher.task_pending) :: :ok
    def registered(task) do
      Logger.debug("DTask.Task.Monitor.Broadcast.registered(#{inspect(task)})")
      GenServer.abcast(@monitor, {:registered, task})
      :ok
    end

    @spec dispatched(Dispatcher.task_id, DateTime.t, node) :: :ok
    def dispatched(task_id, timestamp, node) do
      Logger.debug("DTask.Task.Monitor.Broadcast.dispatched(#{task_id}, #{timestamp}, #{node})")
      GenServer.abcast(@monitor, {:dispatched, task_id, timestamp, node})
      :ok
    end

    @spec progress(Dispatcher.task_id, term) :: :ok
    def progress(task_id, progress) do
      Logger.debug("DTask.Task.Monitor.Broadcast.progress(#{task_id}, #{inspect(progress)})")
      GenServer.abcast(@monitor, {:progress, task_id, progress})
      :ok
    end

    @spec finished(Dispatcher.task_id, DateTime.t, Task.outcome) :: :ok
    def finished(task_id, timestamp, outcome) do
      Logger.debug("DTask.Task.Monitor.Broadcast.finished(#{task_id}, #{timestamp}, #{inspect(outcome)})")
      GenServer.abcast(@monitor, {:finished, task_id, timestamp, outcome})
      :ok
    end
  end
end
