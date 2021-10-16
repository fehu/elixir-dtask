defmodule DTask.ResourceUsage.Extractor do
  @moduledoc false

  @type t() :: module
  @type params :: term
  @type usage :: term

  @callback query_usage(params) :: {:ok, usage} | {:error, term}

  @callback init(params) :: no_return
  @optional_callbacks init: 1
end
