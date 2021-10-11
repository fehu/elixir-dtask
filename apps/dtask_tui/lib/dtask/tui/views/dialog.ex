defmodule DTask.TUI.Views.Dialog do
  @moduledoc false

  alias DTask.TUI

  import DTask.Util.Syntax, only: [<|>: 2]
  import Ratatouille.View

  @callback title(TUI.state)   :: String.t
  @callback body(TUI.state)    :: [Element.t]
  @callback buttons(TUI.state) :: [String.t]
  @callback button_style(TUI.state) :: keyword

  @optional_callbacks title: 1, body: 1, buttons: 1, button_style: 1

  @title_prefix     "[Esc]"
  @title_prefix_sep " "
  @title_suffix     " "

  defmacro __using__(_opts) do
    [v_state, v_title, v_body, v_buttons, v_button_style, t] =
      Macro.generate_arguments(6, __CALLER__.module)

    quote do
      # # # # # Quoted # # # # #
      import Ratatouille.View

      @behaviour TUI.Render
      @behaviour TUI.Views.Dialog

      @impl true
      @spec render(TUI.state) :: Element.t()
      def render(unquote(v_state)) do
        unquote(v_title) =
          case unquote(impl_expr(:title, [v_state], or: nil)) do
            nil        -> unquote(@title_prefix) <> unquote(@title_suffix)
            unquote(t) -> unquote(@title_prefix) <> unquote(@title_prefix_sep) <> unquote(t) <> unquote(@title_suffix)
          end
        unquote(v_body)         = unquote(impl_expr(:body, [v_state], or: nil))
        unquote(v_buttons)      = unquote(impl_expr(:buttons, [v_state], or: []))
        unquote(v_button_style) = unquote(impl_expr(:button_style, [v_state], or: []))

        panel(title: unquote(v_title)) do
          unquote(v_body)
          if unquote(v_buttons) != [] do
            bar do
              for b <- unquote(v_buttons), do: label([{:content, b} | unquote(v_button_style)])
            end
          end
        end
      end
      # # # # # End Quoted # # # # #
    end
  end

  defp impl_expr(func, args, or: default) do
    quote do
      if function_exported?(__MODULE__, unquote(func), unquote(length(args))),
         do: __MODULE__.unquote(func)(unquote_splicing(args)),
         else: unquote(default)
    end
  end

end
