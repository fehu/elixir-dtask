defmodule DTask.Task.Codec do
  @moduledoc """
  Task Serialization and Deserialization.
  """

  alias DTask.Task.DTO

  @type repr :: term

  @type result(x) :: {:ok, x} | {:error, term}

  @callback decode(repr) :: result(DTO.Task.t)
  @callback encode(DTO.Task.t) :: result(repr)

end
