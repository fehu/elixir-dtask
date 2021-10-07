defmodule DTask.Task.DTO.Progress do
  @moduledoc false

  @enforce_keys [:label]
  defstruct     [:label, :step, :total, :time]

  @type t :: %__MODULE__{
               label: String.t,
               step: non_neg_integer | nil,
               total: non_neg_integer | nil,
               time: String.t | nil
             }

  @spec new(
          label :: String.t,
          step  :: non_neg_integer | String.t | nil,
          total :: non_neg_integer | String.t | nil,
          time  :: String.t | nil
        ) :: t
  def new(label, step \\ nil, total \\ nil, time \\ nil)
  def new(label, step, total, time) do
    %__MODULE__{label: label, step: to_int(step), total: to_int(total), time: time}
  end

  defp to_int(arg) do
    case arg do
      nil -> nil
      i when is_integer(i) -> i
      s -> String.to_integer(s)
    end
  end

end
