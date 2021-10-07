defmodule DTask.TUI.Views.ExecutorDetails do
  @moduledoc false

  alias DTask.ResourceUsage.Collector
  alias DTask.TUI.Views.MainView

  use DTask.TUI.Render.Details

  @data_cpu_info DTask.ResourceUsage.Extractor.CpuInfo
  @data_mem_info DTask.ResourceUsage.Extractor.MemInfo
  @data_gpu_info DTask.ResourceUsage.Extractor.NvidiaSmi

  @charts [
    {"GPU (%)",        [@data_gpu_info, :gpu]},
    {"GPU memory (%)", [@data_gpu_info, :mem]},
    {"RAM (%)",        [@data_mem_info, :ram]},
    {"swap (%)",       [@data_mem_info, :swap]},
    {"Total CPU (%)",  [@data_cpu_info, :cpu_total]}
  ]

  @chart_static_height 5

  @grid_size 12

  @label_attributes [Constants.attribute(:underline)]

  @impl true
  @spec render_details(TUI.state, Collector.usage_tuple) :: Element.t
  def render_details(_, {node, :dead}) do
    red = Constants.color(:red)
    panel title: Atom.to_string(node), height: :fill, color: red, padding: 100 do
      label(content: "Connection lost", color: red)
    end
  end

  @impl true
  def render_details(state, {node, _}) do
    hist = render_hist(state, node)
    case state.ui.layout do
      {:split_horizontal, _} ->
        # TODO
        height = MainView.details_height(state) - @chart_static_height * 2
        size = if length(hist) > 0, do: floor(@grid_size / length(hist)), else: 0
        row do
          for render <- hist do
            column(size: size) do
              render.(height)
            end
          end
        end
      {:split_vertical, _} ->
        height = floor(MainView.main_height(state) / length(hist)) - @chart_static_height
        for render <- hist do
          render.(height)
        end
    end
  end

  @impl true
  def render_details(_, other), do: render_inspect(other)

  @coef 0.999999999999999
  @spec render_hist(TUI.state, node) :: [(height -> Element.t)] when height: pos_integer
  def render_hist(state, node) do
    hist = state.data.resource_usage_hist
           |> Stream.map(&Keyword.get(&1, node, :dead))
           |> Enum.filter(&(&1 != :dead))

    Enum.flat_map @charts, fn {label, keys} ->
      series = hist |> Stream.map(&get_in(&1, keys))
                    |> Stream.filter(&is_number/1)
                    |> Enum.map(&(&1 * 100))
      case series |> Stream.uniq |> Enum.take(2) do
        []       -> []
        [unique] -> [&do_plot(label, &1, [unique * @coef | Enum.drop(series, 1)])]
        _        -> [&do_plot(label, &1, series)]
      end
    end
  end

  defp do_plot(label, height, series) do
    panel title: label, attributes: @label_attributes do
      chart(type: :line, series: series, height: height)
    end
  end
end

