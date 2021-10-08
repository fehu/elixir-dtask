defmodule DTask.Util.Syntax do
  @moduledoc false

  defmacro a <|> b do
    [name] = Macro.generate_arguments(1, __MODULE__)
    quote do
      case unquote(a) do
        nil           -> unquote(b)
        unquote(name) -> unquote(name)
      end
    end
  end

  # Functions composition
  defmacro f <<< g do
    [arg] = Macro.generate_arguments(1, __MODULE__)
    quote do
      fn unquote(arg) -> unquote(f).(unquote(g).(unquote(arg))) end
    end
  end

  # Functions composition with reversed arguments
  defmacro f >>> g do
    [arg] = Macro.generate_arguments(1, __MODULE__)
    quote do
      fn unquote(arg) -> unquote(g).(unquote(f).(unquote(arg))) end
    end
  end

  @spec maybe(x | nil, (x -> y)) :: y | nil when x: term, y: term
  def maybe(nil, _), do: nil
  def maybe(x, f), do: f.(x)
end
