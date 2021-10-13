defmodule DTask.TUI.Views.Dialog do
  @moduledoc false

  alias DTask.TUI

  import Ratatouille.View

  @callback title(TUI.state)   :: String.t
  @callback body(TUI.state)    :: [Element.t]

  @typep button :: String.t | {String.t, keyword}
  @callback buttons(TUI.state) :: [button]


  @grid_size 12

  @title_0 "[Esc]"

  defmacro __using__(_opts) do
    quote do
      # # # # # Quoted # # # # #
      import Ratatouille.View

      @behaviour TUI.Render
      @behaviour TUI.Views.Dialog

      @impl TUI.Render
      @spec render(TUI.state) :: Element.t()
      def render(state) do
        buttons = __MODULE__.buttons(state) |> Enum.map(fn
          {txt, style} -> label([{:content, txt} | style])
          txt          -> label(content: txt)
        end)
        buttons_bar = if buttons != [] do
          col_i_size = round(unquote(@grid_size) / (length(buttons) + 1))
          col_i = column(size: col_i_size)
          buttons_i = buttons |> Enum.map(&column([size: 1], [&1]))
                              |> Enum.intersperse(column(size: col_i_size))
          row do
            [col_i] ++ buttons_i ++ [col_i]
          end
        end

        panel(title: unquote(@title_0), height: :fill) do
          panel(title: __MODULE__.title(state), height: :fill) do
            # Body
            __MODULE__.body(state)
          end
          # Buttons
          buttons_bar
        end
      end

      @impl TUI.Views.Dialog
      def title(_), do: ""

      @impl TUI.Views.Dialog
      def body(_), do: []

      @impl TUI.Views.Dialog
      def buttons(_), do: []

      @impl TUI.Views.Dialog
      def button_style(_), do: []

      defoverridable title: 1, body: 1, buttons: 1, button_style: 1
      # # # # # End Quoted # # # # #
    end
  end

end
