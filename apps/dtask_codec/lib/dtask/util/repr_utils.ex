defmodule DTask.Util.ReprUtils do
  @moduledoc false

  def is_nil(x),    do: x == nil
  def is_struct(x), do: is_map(x) and is_map_key(x, :__struct__)

  @typep enum(_x)       :: Enumerable.t
  @typep result(x)      :: {:ok, x}       | {:error, term}
  @typep collect_out(x) :: {:ok, enum(x)} | {:error, enum(result(x))}

  @spec collect(enum(x), (x -> result(y))) :: collect_out(y)
        when x: term, y: term
  def collect(coll, f) do
    result = Enum.map(coll, &f.(&1))
    has_error? = Enum.any? result, fn
      {:error, _}  -> true
      _            -> false
    end
    unless has_error?,
           do: {:ok, Enum.map(result, &elem(&1, 1))},
           else: {:error, result}
  end

  @spec collect_arr((x -> result(y))) :: (enum(x) -> collect_out(y))
        when x: term, y: term
  def collect_arr(f), do: &collect(&1, f)

end
