defmodule DTask.Task.DTO.Free do
  @moduledoc """
  Denotes data of variable structure.
  """

  @enforce_keys [:data]
  defstruct     [:data]

  @type t()  :: t(any)
  @type t(x) :: %__MODULE__{
                  data: x
                }

  @spec wrap(x) :: t(x) when x: term
  def wrap(x) do
    case x do
      free=%__MODULE__{} -> free
      other              -> %__MODULE__{data: other}
    end
  end
end
