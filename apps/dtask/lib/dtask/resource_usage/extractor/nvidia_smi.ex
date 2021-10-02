defmodule DTask.ResourceUsage.Extractor.NvidiaSmi do
  @moduledoc false

  @behaviour DTask.ResourceUsage.Extractor

  @typep value :: number | :nan
  @type usage :: %{gpu: value, mem: value}

  @typep ignored :: term

  @impl true
  @spec query_usage(ignored) :: {:ok, usage} | {:error, term}
  def query_usage(_) do
    params = [
      "--query-gpu=utilization.gpu,utilization.memory",
      "--format=csv,noheader,nounits"
    ]
    with {csv, 0}   <- System.cmd("nvidia-smi", params),
         [gpu, mem] <- String.split(csv, ",") |> Enum.map(&parse_usage/1),
         usage = %{gpu: gpu, mem: mem}
      do
        {:ok, usage}
      else
        other -> {:error, other}
      end
  end

  defp parse_usage(raw) do
    case String.trim(raw) do
      "[N/A]" -> :nan
      num     -> String.to_integer(num)
    end
  end

end
