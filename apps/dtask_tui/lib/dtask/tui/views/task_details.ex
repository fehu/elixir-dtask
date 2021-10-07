defmodule DTask.TUI.Views.TaskDetails do
  @moduledoc false

  alias DTask.TUI
  alias DTask.TUI.Views.{MainView, TaskCommon}

  use DTask.TUI.Render.Details

  @default_color TaskCommon.default_color
  @pending_label TaskCommon.pending_label |> String.capitalize
  @pending_color TaskCommon.pending_color
  @running_label TaskCommon.running_label |> String.capitalize
  @running_color Constants.color(:green)
  @success_label TaskCommon.success_label |> String.capitalize
  @success_color TaskCommon.success_color
  @failure_label TaskCommon.failure_label |> String.capitalize
  @failure_color TaskCommon.failure_color

  @subtitle_attrs [Constants.attribute(:bold)]
  @subtitle_style [attributes: @subtitle_attrs]

  @par_attrs [Constants.attribute(:bold), Constants.attribute(:underline)]

  @max_progress_width 40

  @impl true
  @spec render_details(TUI.state, term) :: Element.t
  def render_details(state, {id, {{task, params}, task_state}}) do
    title = "[#{id}] #{TaskCommon.atom_to_string_short(task)} "

    progress_elems = case task_state do
      {:running, s} ->
        progress_width = max MainView.details_width(state), @max_progress_width
        [
          kv("Node", s.node),
          label([content: s.progress.label] ++ @subtitle_style),
          label(content: TaskCommon.show_progress_bar(s.progress, progress_width))
        ]
      _ -> []
    end
    result_elems = case task_state do
      {:finished, s} ->
        [
          kv("Node", s.node),
          kv("Duration", TaskCommon.show_duration(DateTime.diff s.finished, s.dispatched))
        ] ++ case s.outcome do
          {:success, result} ->
            # TODO
            [par("Result", inspect(result, pretty: true, width: 0))]
          {:failure, error} ->
            [par("Error", inspect(error, pretty: true, width: 0), color: @failure_color)]
        end
      _ -> []
    end

    elems = [render_state_label(task_state)]
         ++ progress_elems
         ++ [par("Parameters", TaskCommon.show_params(params), wrap: true)]
         ++ result_elems

    panel([title: title, height: :fill], Enum.intersperse(elems, label()))
  end

  defp par(title, text, opts \\ []), do: [
    label(
      content: title,
      attributes: @par_attrs,
      color: Keyword.get(opts, :color, @default_color)
    ),
    label(
      content: text,
      wrap: Keyword.get(opts, :wrap, false)
    )
  ]

  defp kv(key, value) do
    label do
      text(content: key <> ": ", attributes: @subtitle_attrs)
      text(content: to_string(value))
    end
  end

  defp render_state_label(task_state) do
    params = case task_state do
      :pending       -> [content: @pending_label, color: @pending_color]
      {:running, _}  -> [content: @running_label, color: @running_color]
      {:finished, s} ->
        case s.outcome do
          {:success, _} -> [content: @success_label, color: @success_color]
          {:failure, _} -> [content: @failure_label, color: @failure_color]
        end
    end
    label(params ++ @subtitle_style)
  end

end
