defmodule DTask.ResourceUsage.Extractor.MemInfo do
  @moduledoc false

  @behaviour DTask.ResourceUsage.Extractor

  @typep value :: number | :nan
  @type usage :: %{ram: value, swap: value}

  @typep ignored :: term

  @regex_mem_total ~r"MemTotal:\s*(\d+) kB"
  @regex_mem_avail ~r"MemAvailable:\s*(\d+) kB"

  @regex_swap_total ~r"SwapTotal:\s*(\d+) kB"
  @regex_swap_free  ~r"SwapFree:\s*(\d+) kB"

  @impl true
  @spec query_usage(ignored) :: {:ok, usage} | {:error, term}
  def query_usage(_) do
    with {:ok, data}       <- File.read("/proc/meminfo"),
         [_, s_mem_total]  <- Regex.run(@regex_mem_total, data),
         [_, s_mem_avail]  <- Regex.run(@regex_mem_avail, data),
         [_, s_swap_total] <- Regex.run(@regex_swap_total, data),
         [_, s_swap_free]  <- Regex.run(@regex_swap_free, data),
         {mem_total, ""}   <- Integer.parse(s_mem_total),
         {mem_avail, ""}   <- Integer.parse(s_mem_avail),
         {swap_total, ""}  <- Integer.parse(s_swap_total),
         {swap_free, ""}   <- Integer.parse(s_swap_free)
      do {:ok, %{
           ram: 1 - mem_avail / mem_total,
           swap: (if swap_total == 0, do: :nan, else: 1 - swap_free / swap_total)
         }}
      else
        {:error, e} -> {:error, e}
        _           -> {:error, "Failed to parse /proc/meminfo"}
    end
  end
end
