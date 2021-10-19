defmodule DTask.Task do
  @moduledoc false

  alias DTask.Task.Reporter

  @type t() :: module
  @type local_params :: term
  @type remote_params :: term
  @type outcome :: {:success, term} | {:failure, term}

  @callback exec(Reporter.t, local_params, remote_params) :: outcome
end
