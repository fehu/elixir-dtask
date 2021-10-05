defmodule DTask.ResourceUsage.Extractor.NvidiaSmi do
  @moduledoc false

  @behaviour DTask.ResourceUsage.Extractor

  @typep value :: number | :nan
  @type usage :: %{gpu: value, mem: value}

  @typep ignored :: term

  @impl true
  @spec query_usage(ignored) :: {:ok, usage} | {:error, term}
  def query_usage(_) do
    with {:ok, csv} <- try_cmd(),
         [gpu, mem] <- String.split(csv, ",") |> Enum.map(&parse_usage/1),
         usage = %{gpu: gpu, mem: mem}
      do
        {:ok, usage}
      else
        error={:error, _} -> error
        other             -> {:error, other}
      end
  end

  @cmd "nvidia-smi"
  @params [
    "--query-gpu=utilization.gpu,utilization.memory",
    "--format=csv,noheader,nounits"
  ]

  defp try_cmd do
    try do
      case System.cmd(@cmd, @params) do
        {out, 0} -> {:ok, out}
        {out, c} -> {:error, {:non_zero_exit, c, out}}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp parse_usage(raw) do
    case String.trim(raw) do
      "[N/A]" -> :nan
      num     -> String.to_integer(num)
    end
  end

end
