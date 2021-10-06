defmodule DTask.TUI.Update do
  @moduledoc false

  alias DTask.{ResourceUsage, Task}
  alias DTask.TUI.State

  alias Ratatouille.Runtime.Command

  @offset_x_step 5

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
    data = state.data[state.ui.table.data_key]
    max = if data, do: Enum.count(data), else: 0
    cursor = fn -> state.ui.table.cursor end
    {cond, upd_state} = case op do
      :+   -> {cursor.() < max, fn -> update_in(state.ui.table.cursor, &(&1 + 1)) end}
      :max -> {true,            fn -> put_in(state.ui.table.cursor, max) end}
      i    -> {i <= max,        fn -> put_in(state.ui.table.cursor, i) end}
    end
    if cond, do: upd_state.(), else: state
  end

  # Operations that require knowing number of columns
  def move_cursor(state, :x, :+) do
    columns = state.ui.table.count_columns.(state)
    if state.ui.table.offset_x < columns,
       do: update_in(state.ui.table.offset_x, &(&1 + @offset_x_step)),
       else: state
  end

  def move_cursor(state, :x, :-) do
    if state.ui.table.offset_x > 0,
       do: update_in(state.ui.table.offset_x, &(&1 - @offset_x_step)),
       else: state
  end
  def move_cursor(state, :x, 0),  do: put_in(state.ui.table.offset_x, 0)

  # Other operations along axis :x are not supported
  def move_cursor(state, :x, _), do: state

end
