defmodule DTask.ResourceUsage.Extractor.Combined do
  @moduledoc false

  alias DTask.ResourceUsage.Extractor

  @behaviour Extractor

  require Logger

  @typep extractors :: [{Extractor.t, Extractor.params}, ...]

  @impl true
  @spec query_usage(params) :: {:ok, usage} | {:error, term}
        when params: extractors | {extractors, combine: combine},
             combine: ([{Extractor.t, Extractor.usage}, ...] -> {:ok, usage} | {:error, error}),
             usage: usage_custom | %{Extractor.t => Extractor.usage},
             error: term,
             usage_custom: term

  def query_usage(extractors) when is_list(extractors),
      do: query_usage({extractors, combine: &{:ok, Map.new(&1)}})

  def query_usage({extractors, combine: combine}) do
    extracted = Enum.flat_map extractors, fn {ext, ps} ->
      case ext.query_usage(ps) do
        {:ok, usage} -> [{ext, usage}]
        {:error, e}  ->
          Logger.warning("#{ext} failed to extract resource usage: #{inspect(e)}")
          []
      end
    end
    case extracted do
      [] -> {:error, "Failed to extract resource usage: #{inspect(extractors)}}"}
      _  -> combine.(extracted)
    end
  end

end
