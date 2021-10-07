defmodule DTask.TUI.Views.TasksTable do
  @moduledoc false

  alias DTask.Task.{Dispatcher, Monitor}
  alias DTask.TUI

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

  @pending_label "pending"
  @pending_color Constants.color(:default)

  @running_label "running"
  @running_color Constants.color(:cyan)

  @success_label "success"
  @success_color Constants.color(:blue)

  @failure_label "failure"
  @failure_color Constants.color(:red)

  @progress_symbol "█"
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
          show_timestamp(s.dispatched),
          show_progress(s),
          ""
        }
      {:finished, s=%{outcome: {outcome, _}}} ->
        {
          if(outcome == :success, do: @success_color, else: @failure_color),
          show_timestamp(s.dispatched),
          if(outcome == :success, do: @success_label, else: @failure_label),
          show_timestamp(s.finished)
        }
    end
    style_0 = if selected?, do: @row_selected_style, else: @row_style
    table_row([color: color] ++ style_0) do
      table_cell(content: to_string(id))
      table_cell(content: to_string(task))
      table_cell(content: dispatched)
      table_cell(content: state)
      table_cell(content: finished)
    end
  end

  defp show_timestamp(timestamp) do
    %DateTime{month: month, day: day, hour: hour, minute: min, second: sec} =
      TUI.Util.shift_time_zone(timestamp)
    l2 = &String.pad_leading(to_string(&1), 2, "0")

    "#{l2.(day)}/#{l2.(month)} #{l2.(hour)}:#{l2.(min)}:#{l2.(sec)}"
  end

  defp show_progress(%{label: label, percent: percent, step: step, total: total, time: time}) do
    "#{label}: [#{show_progress_bar(percent)}] #{step}/#{total} (#{time})"
  end
  defp show_progress(_), do: @running_label

  defp show_progress_bar(percent_string) do
    {percent, ""} = Integer.parse(percent_string)
    progress = round(@progress_width * percent / 100)
    String.duplicate(@progress_symbol, progress) <> String.duplicate("", @progress_width - progress)
  end
end
