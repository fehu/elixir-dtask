defmodule DTask.Task do
  @moduledoc false

  alias DTask.Task.Dispatcher

  @type t() :: module
  @type params :: term

  @callback exec(Dispatcher.server, params) :: no_return
end
