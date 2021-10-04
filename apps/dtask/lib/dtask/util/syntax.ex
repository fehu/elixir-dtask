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

end
