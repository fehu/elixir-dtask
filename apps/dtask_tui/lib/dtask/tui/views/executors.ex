defmodule DTask.TUI.Views.Executors do
  @moduledoc false

  alias Ratatouille.Constants
  import Ratatouille.View

  @data_cpu_info DTask.ResourceUsage.Extractor.CpuInfo
  @data_mem_info DTask.ResourceUsage.Extractor.MemInfo
  @data_gpu_info DTask.ResourceUsage.Extractor.NvidiaSmi

  @table_title "Executors"

  @table_columns_0 [
    {"Node", :node},
    {"GPU",  [@data_gpu_info, :gpu]},
    {"VMem", [@data_gpu_info, :mem]},
    {"RAM",  [@data_mem_info, :ram]},
    {"swap", [@data_mem_info, :swap]},
    {"CPU*", [@data_cpu_info, :cpu_total]}
  ]
  @table_header_cpus "CPU"
  @data_cpus [@data_cpu_info, :cpus]

  @table_header_0    @table_columns_0 |> Enum.map(&elem(&1, 0))
  @table_data_keys_0 @table_columns_0 |> Enum.map(&elem(&1, 1))
  @table_columns_n_0 Enum.count(@table_columns_0)

  @table_header_style [
    attributes: [Constants.attribute(:bold)]
  ]
  @row_selected_style [
    color: Constants.color(:black),
    background: Constants.color(:white)
  ]

  @dead_row_style [
    color: Constants.color(:red)
  ]
  @dead_row_selected_style [
    color: Constants.color(:black),
    background: Constants.color(:red)
  ]

  @spec render_table(TUI.state) :: Element.t
  def render_table(state) do
    data = state.data.resource_usage
    n_cpus =
      if data,
         do: data |> Stream.map(&elem(&1, 1))
                  |> Stream.filter(&is_map/1)
                  |> Stream.map(&get_in(&1, [@data_cpu_info, :cpus]))
                  |> Stream.filter(&is_map/1)
                  |> Stream.map(&Enum.count/1)
                  |> Enum.max(&>/2, fn -> 0 end),
         else: 0
    panel(title: @table_title, height: :fill) do
      # TODO
      viewport() do
        table do
          render_table_header(n_cpus)
          if data, do: data |> Enum.map(&render_table_row(&1, n_cpus))
        end
      end
    end
  end

  defp render_table_header(n_cpus) do
    cpus_header = if n_cpus > 0,
                     do: Enum.map(1..n_cpus, &"#{@table_header_cpus}#{&1}"),
                     else: []
    table_row(@table_header_style) do
      for header <- @table_header_0 ++ cpus_header do
        table_cell(content: header)
      end
    end
  end

  defp render_table_row({node, :dead}, n_cpus) do
    # TODO
    selected? = false
    table_row(if(selected?, do: @dead_row_selected_style, else: @dead_row_style)) do
      table_cell(content: to_string(node))
      for i <- 1 .. @table_columns_n_0 + n_cpus - 1 do
        table_cell(content: "")
      end
    end
  end

  defp render_table_row({node, usage}, n_cpus) do
    # TODO
    selected? = false
    table_row(if(selected?, do: @row_selected_style, else: [])) do
      Enum.map @table_data_keys_0, fn
        :node -> table_cell(content: to_string(node))
        keys  -> table_cell(content: percent(get_in(usage, keys)))
      end

      if n_cpus > 0 do
        for i <- 1..n_cpus do
          table_cell(content: percent(get_in(usage, @data_cpus)[i]))
        end
      end
    end
  end

  @spec percent(float | :nan | nil) :: String.t
  defp percent(nil),   do: ""
  defp percent(:nan),  do: "N/A"
  defp percent(float), do: "#{round(float * 100)}%"
end
