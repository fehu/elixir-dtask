defmodule DTask.TUI.Update do
  @moduledoc false

  alias DTask.{ResourceUsage, Task}
  alias DTask.TUI.{State, Tab}

  alias Ratatouille.Runtime.Command

  @typep data :: :tasks
               | :resource_usage

  @spec request_refresh(data) :: Command.t
  def request_refresh(:tasks) do
    Command.new &Task.Monitor.get_state/0,
                {:refreshed, :tasks}
  end

  def request_refresh(:resource_usage) do
    Command.new &ResourceUsage.Collector.get_usage/0,
                {:refreshed, :resource_usage}
  end

  @spec tab(State.t, Tab.t) :: State.t
  def tab(state, tab),
      do: put_in(state.ui.tab, Tab.init(tab))

  @spec layout(State.t, State.UI.layout) :: State.t
  def layout(state, layout),
      do: put_in(state.ui.layout, layout)

  @spec close_overlay(State.t) :: State.t()
  defdelegate close_overlay(state), to: DTask.TUI.Overlay, as: :close

end
