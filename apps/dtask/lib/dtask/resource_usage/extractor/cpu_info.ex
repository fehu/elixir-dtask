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
  @spec init(param) :: module
  def init(_), do: Agent.start_link(fn -> nil end, name: __MODULE__)

  @impl true
  @spec query_usage(param) :: {:ok, usage} | {:error, term}
  def query_usage(param \\ nil) do
    with {:ok, usage} <- do_query_usage(param) do
      prev_usage = Agent.get_and_update(__MODULE__, &{&1, usage})
      if prev_usage do
        diff = deep_merge prev_usage, usage, fn {idle_p, total_p}, {idle, total} ->
          idle_d = idle - idle_p
          total_d = total - total_p

          (total_d - idle_d) / total_d
        end
        {:ok, diff}
      else
        {:ok, %{}}
      end
    end

  end

  @spec do_query_usage(param) :: {:ok, usage} | {:error, term}
  defp do_query_usage(param \\ nil) do
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
          err             -> {:error, err}
        end
      end
      case usage do
        err={:error, _} -> err
        _               -> {:ok, usage}
      end
    end
  end

  @max_idx      9
  @idle_idx     [3, 4]
  @idle_idx_rev @idle_idx |> Enum.map(&(@max_idx - &1))

  @spec parse_usage(String.t) :: {:ok, {idle :: non_neg_integer, total :: non_neg_integer}}
                               | {:error, term}
  defp parse_usage(s_stats) do
    stats_rev = Enum.reduce s_stats, {:ok, []}, fn
      _, e={:error, _} -> e
      s, {:ok, acc} ->
        case Integer.parse(s) do
          {int, ""} -> {:ok, [int | acc]}
          _         -> {:error, "Not an integer: '#{s}'"}
        end
    end

    with {:ok, stats_rev} <- stats_rev,
         idle = Stream.with_index(stats_rev)
                |> Stream.filter(&elem(&1, 1) in @idle_idx_rev)
                |> Stream.map(&elem(&1, 0))
                |> Enum.sum,
         total = Enum.sum(stats_rev),
      do: {:ok, {idle, total}}
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

  defp deep_merge(m1, m2, f),
       do: Map.merge m1, m2, fn
         _, v1, v2 when is_map(v1) and is_map(v2) -> deep_merge(v1, v2, f)
         _, v1, v2 when is_function(f, 2) -> f.(v1, v2)
         k, v1, v2 when is_function(f, 3) -> f.(k, v1, v2)
       end
end
