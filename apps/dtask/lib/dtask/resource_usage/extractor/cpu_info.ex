defmodule DTask.ResourceUsage.Extractor.CpuInfo do
  @moduledoc false

  @behaviour DTask.ResourceUsage.Extractor

  @type param :: :each | nil
  
  @typep cpu_n :: non_neg_integer
  @type usage :: %{
                   required(:cpu_total) => number,
                   optional(:cpus)      => %{cpu_n => number}
                 }

  @error {:error, "Failed to read /proc/stat"}

  @impl true
  @spec query_usage(param) :: {:ok, usage} | {:error, term}
  def query_usage(param \\ nil) do
    read = if param == :each,
              do: fn line -> Enum.take_while(line, &String.starts_with?(&1, "cpu")) end,
              else: &Enum.take(&1, 1)
    try_lines =
      try do
        {:ok, read.(File.stream!("/proc/stat"))}
      rescue
        _ -> @error
      end

    with {:ok, lines} <- try_lines do
      acc0 = if param == :each, do: %{cpus: %{}}, else: %{}
      usage = Enum.reduce lines, acc0, fn line, acc1 ->
        with acc when is_map(acc) <- acc1,
             ["cpu" <> s_cpu_n | s_stats] <- String.split(line),
             {:ok, usage}                 <- parse_usage(s_stats),
             {:ok, cpu_k}                 <- parse_cpu_key(s_cpu_n)
        do
          put_in(acc, cpu_k, usage)
        else
          err={:error, _} -> err
          _               -> @error
        end
      end
      case usage do
        err={:error, _} -> err
        _               -> {:ok, usage}
      end
    end
  end

  @idle_index 3
  defp parse_usage(s_stats) do
    stats_rev = Enum.reduce s_stats, [], fn
      _, :error -> :error
      s, acc    -> with {int, _} <- Integer.parse(s),
                        do: [int | acc]
    end
    idle_index_rev = length(s_stats) - @idle_index - 1
    case Enum.at(stats_rev, idle_index_rev) do
      nil  -> {:error, "Out of index #{idle_index_rev}"}
      idle -> {:ok, 1 - idle / Enum.sum(stats_rev)}
    end
  end

  @spec parse_cpu_key(String.t) :: {:ok, [atom | pos_integer, ...]} | :error
  defp parse_cpu_key(""),
       do: {:ok, [:cpu_total]}
  defp parse_cpu_key(s) do
    with {n, ""} <- Integer.parse(s) do
      {:ok, [:cpus, n + 1]}
    else
      _ -> :error
    end
  end

  defp stats_diff_rec(stats1, stats2, time_delta) do
    Map.merge stats1, stats2, fn
      _, v1, v2 when is_number(v1) and is_number(v2) -> (v2 - v1) / time_delta
      _, v1, v2 when is_map(v1)    and is_map(v2)    -> stats_diff_rec(v1, v2, time_delta)
      _, _, _                                        -> nil
    end
  end
end
