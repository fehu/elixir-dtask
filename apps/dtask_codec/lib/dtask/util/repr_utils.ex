defmodule DTask.Util.ReprUtils do
  @moduledoc false

  def is_nil(x),    do: x == nil
  def is_struct(x), do: is_map(x) and is_map_key(x, :__struct__)
end
