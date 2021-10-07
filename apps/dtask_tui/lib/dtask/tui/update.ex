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

  @spec move_cursor(State.t, axis, op) :: State.t when axis: :x | :y,
                                                       op: :+ | :- | :max | non_neg_integer
  def move_cursor(state, :y, :-) do
    if state.ui.table.cursor > 0,
       do: update_in(state.ui.table.cursor, &(&1 - 1)),
       else: state
  end

  def move_cursor(state, :y, 0), do: put_in(state.ui.table.cursor, 0)

  # Operations that require knowing data size
  def move_cursor(state, :y, op) when op == :+
                                   or op == :max
                                   or (is_integer(op) and op > 0) do
    data = state.data[state.ui.tab.data_key]
    max = if data, do: Enum.count(data), else: 0
    cursor = fn -> state.ui.table.cursor end
    {cond, upd_state} = case op do
      :+   -> {cursor.() < max - 1, fn -> update_in(state.ui.table.cursor, &(&1 + 1)) end}
      :max -> {true,                fn -> put_in(state.ui.table.cursor, max - 1) end}
      i    -> {i <= max,            fn -> put_in(state.ui.table.cursor, i) end}
    end
    if cond, do: upd_state.(), else: state
  end

  # Other operations are not supported
  def move_cursor(state, _, _), do: state

  @spec tab(State.t, Tab.t) :: State.t
  def tab(state, tab) do
    state |> put_in([:ui, :tab], tab)
          |> put_in([:ui, :table], %State.UI.Table{})
  end

  @spec layout(State.t, State.UI.layout) :: State.t
  def layout(state, layout),
      do: put_in(state.ui.layout, layout)

end
