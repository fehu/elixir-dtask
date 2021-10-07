defmodule DTask.TUI.Views.TasksTable do
  @moduledoc false

  alias DTask.Task.{Dispatcher, Monitor}
  alias DTask.TUI
  alias DTask.TUI.Views.TaskCommon

  import DTask.Util.Syntax

  use DTask.TUI.Render.Table

  @table_title "Tasks"

  @data_key :tasks

  @header_style [
    attributes: [Constants.attribute(:bold)]
  ]

  @row_style []
  @row_selected_style [
    color: Constants.color(:black),
    background: Constants.color(:white)
  ]

  @pending_label TaskCommon.pending_label
  @pending_color TaskCommon.pending_color
  @running_label TaskCommon.running_label
  @running_color TaskCommon.running_color
  @success_label TaskCommon.success_label
  @success_color TaskCommon.success_color
  @failure_label TaskCommon.failure_label
  @failure_color TaskCommon.failure_color

  @progress_width  10

  @type row :: {Dispatcher.task_id, {Dispatcher.task_descriptor, Monitor.task_state}}

  @impl true
  @spec table_title :: String.t
  def table_title, do: @table_title

  @impl true
  @spec data_key :: atom
  def data_key, do: @data_key

  @impl true
  @spec render_header(TUI.state, any) :: Element.t
  def render_header(_state, _cached) do
    table_row(@header_style) do
      table_cell(content: "#")
      table_cell(content: "Task")
      table_cell(content: "Dispatched")
      table_cell(content: "State")
      table_cell(content: "Finished")
    end
  end

  @impl true
  @spec render_row(row, any, boolean) :: Element.t
  def render_row(row, _cached, selected?) do
    {id, {{task, _}, state}} = row
    {color, dispatched, state, finished} = case state do
      :pending ->
        {
          @pending_color,
          "",
          @pending_label,
          ""
        }
      {:running,  s} ->
        {
          @running_color,
          TaskCommon.show_date_time(s.dispatched),
          TaskCommon.show_progress(s.progress, @progress_width) <|> @running_label,
          ""
        }
      {:finished, s=%{outcome: {outcome, _}}} ->
        {
          if(outcome == :success, do: @success_color, else: @failure_color),
          TaskCommon.show_date_time(s.dispatched),
          if(outcome == :success, do: @success_label, else: @failure_label),
          TaskCommon.show_date_time(s.finished)
        }
    end
    style_0 = if selected?, do: @row_selected_style, else: @row_style
    table_row([color: color] ++ style_0) do
      table_cell(content: to_string(id))
      table_cell(content: TaskCommon.atom_to_string_short(task))
      table_cell(content: dispatched)
      table_cell(content: state)
      table_cell(content: finished)
    end
  end

end
