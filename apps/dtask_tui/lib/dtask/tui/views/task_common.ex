defmodule DTask.TUI.Views.TaskCommon do
  @moduledoc false

  alias DTask.Task.DTO.Progress
  alias DTask.TUI
  alias Ratatouille.Constants

  import DTask.Util.Syntax

  @default_color Constants.color(:default)

  @pending_label "pending"
  @pending_color @default_color

  @running_label "running"
  @running_color Constants.color(:cyan)

  @success_label "success"
  @success_color Constants.color(:blue)

  @failure_label "failure"
  @failure_color Constants.color(:red)

  @progress_symbol "█"

  def default_color, do: @default_color
  def pending_label, do: @pending_label
  def pending_color, do: @pending_color
  def running_label, do: @running_label
  def running_color, do: @running_color
  def success_label, do: @success_label
  def success_color, do: @success_color
  def failure_label, do: @failure_label
  def failure_color, do: @failure_color

  @spec atom_to_string_short(atom) :: String.t
  def atom_to_string_short(a),
      do: Atom.to_string(a) |> String.split(".") |> List.last

  @spec show_date_time(DateTime.t) :: String.t
  def show_date_time(timestamp) do
    %DateTime{month: month, day: day, hour: hour, minute: min, second: sec} =
      TUI.Util.shift_time_zone(timestamp)

    "#{l2 day}/#{l2 month} #{l2 hour}:#{l2 min}:#{l2 sec}"
  end

  defp l2(s), do: String.pad_leading(to_string(s), 2, "0")

  @units [
    :microsecond,
    :second,
    :minute,
    :hour
  ]
  @def [
    {:microsecond, 1000},
    {:second, 60},
    {:minute, 60},
    {:hour, 12},
    {:day, nil}
  ]
  @spec show_duration(pos_integer, atom) :: String.t
  def show_duration(val0, unit \\ :second) when unit in @units do
    segments = Enum.drop_while(@def, &(elem(&1, 0) != unit))
    {_, segments} = Enum.reduce segments, {val0, []}, fn
      _ , acc={0, _} ->
        acc
      {unit, n}, {val, acc} ->
        next = if n, do: floor(val / n), else: val
        rest = val - (next * n)
        new_acc = case rest do
          0 -> acc
          _ ->
            unit_s = to_string(unit)
            unit_s = unless rest == 1, do: unit_s <> "s", else: unit
            ["#{rest} #{unit_s}" | acc]
        end
        {next, new_acc}
    end
    unless Enum.empty?(segments),
           do: Enum.join(segments, " "),
           else: "0 #{to_string(unit)}s"
  end

  @spec show_progress(term, pos_integer) :: String.t | nil
  def show_progress(p=%Progress{label: label, step: step, total: total}, progress_width) do
    time = maybe(Map.get(p, :time), &" (#{&1})") <|> ""

    "#{label}: [#{show_progress_bar(step / total, progress_width)}] #{step}/#{total}" <> time
  end
  def show_progress(%Progress{label: label}, _), do: label
  def show_progress(_, _), do: nil

  @spec show_progress_bar(float | Progress.t, pos_integer) :: String.t
  def show_progress_bar(progress, progress_width) when is_struct(progress, Progress) do
    percent = if progress.total, do: progress.step / progress.total, else: 1.0
    show_progress_bar(percent, progress_width)
    end
  def show_progress_bar(percent, progress_width) when is_float(percent) do
    progress = round(progress_width * percent)
    String.duplicate(@progress_symbol, progress) <> String.duplicate(" ", progress_width - progress)
  end

  @spec show_params(params, sep) :: String.t when params: {atom, term} | term,
                                                  sep: String.t
  def show_params(params, sep \\ ", ") do
     Enum.join do_show_params(params, sep), sep
  end

  defp do_show_params(params, sep) do
    if Enumerable.impl_for(params) do
      Enum.map params, fn
        {k, v} ->
          v_s = case do_show_params(v, sep) do
            [one] -> one
            many  -> "[" <> Enum.join(many, sep) <> "]"
          end
          "#{k}: #{v_s}"
        k ->
          to_string(k)
      end
    else
      [to_string(params)]
    end
  end

end
