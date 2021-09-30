defmodule DTask.Task do
  @moduledoc false

  alias DTask.Task.Reporter

  @type t() :: module
  @type params :: term
  @type outcome :: {:success, term} | {:failure, term}

  @callback exec(Reporter.t, params) :: outcome
end
