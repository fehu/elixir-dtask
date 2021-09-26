defmodule DTask.ResourceUsage.Extractor do
  @moduledoc false

  @type t() :: module
  @type params :: term
  @type usage :: term

  @callback query_usage(params) :: {:ok, usage} | {:error, term}

end
