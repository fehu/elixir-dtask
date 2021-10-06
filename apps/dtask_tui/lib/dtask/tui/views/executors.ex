defmodule DTask.TUI.Views.Executors do
  @moduledoc false

  alias DTask.TUI.State

  alias Ratatouille.Constants
  import Ratatouille.View

  @data_cpu_info DTask.ResourceUsage.Extractor.CpuInfo
  @data_mem_info DTask.ResourceUsage.Extractor.MemInfo
  @data_gpu_info DTask.ResourceUsage.Extractor.NvidiaSmi

  @table_title "Executors"
  @table_header_style [
    attributes: [Constants.attribute(:bold)]
  ]
  @row_selected_style [
    color: Constants.color(:black),
    background: Constants.color(:white)
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
          # Header
          table_row(@table_header_style) do
            table_cell(content: "Node")
            table_cell(content: "GPU")
            table_cell(content: "GPU MEM")
            table_cell(content: "RAM")
            table_cell(content: "SWAP")
            table_cell(content: "CPU")

            if n_cpus > 0 do
              for i <- 1..n_cpus do
                table_cell(content: "CPU#{i}")
              end
            end
          end

          # Rows
          if data do
            for {node, usage} <- data do
              # TODO: handle usage == :dead
              cpu = usage[@data_cpu_info]
              mem = usage[@data_mem_info]
              gpu = usage[@data_gpu_info]

              # TODO
              selected? = false

              table_row(if(selected?, do: @row_selected_style, else: [])) do
                table_cell(content: to_string(node))
                table_cell(content: percent(gpu[:gpu]))
                table_cell(content: percent(gpu[:mem]))
                table_cell(content: percent(mem[:ram]))
                table_cell(content: percent(mem[:swap]))
                table_cell(content: percent(cpu[:cpu_total]))

                if n_cpus > 0 do
                  for i <- 1..n_cpus do
                    table_cell(content: percent(cpu.cpus[i]))
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  @spec percent(float | :nan | nil) :: String.t
  defp percent(nil),   do: ""
  defp percent(:nan),  do: "N/A"
  defp percent(float), do: "#{round(float * 100)}%"
end
