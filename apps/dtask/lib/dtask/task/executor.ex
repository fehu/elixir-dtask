defmodule DTask.Task.Executor do
  @moduledoc false

  alias DTask.Task

  use GenServer

  @spec start_link(Dispatcher.server) :: GenServer.on_start
  def start_link(dispatcher) do
    GenServer.start_link(__MODULE__, dispatcher, name: __MODULE__)
  end

  @spec exec_task(GenServer.server, Task.t, Task.params) :: :ok
  def exec_task(server, task, params) do
    GenServer.cast(server, {:exec, task, params})
  end

  # # # Callbacks # # #

  @impl true
  def init(dispatcher) do
    {:ok, dispatcher}
  end

  @impl true
  def handle_cast({:exec, task, params}, dispatcher) do
    task.exec(dispatcher, params)
    {:noreply, nil}
  end
end