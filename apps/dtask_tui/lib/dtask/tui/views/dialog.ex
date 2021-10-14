defmodule DTask.TUI.Views.Dialog do
  @moduledoc false

  alias DTask.TUI
  alias Ratatouille.Constants

  import Ratatouille.View

  @callback title(TUI.state)   :: String.t
  @callback body(TUI.state)    :: [Element.t]

  @typep button :: String.t | {String.t, keyword}
  @callback buttons(TUI.state) :: [button]

  @type overlay_cfg :: term
  @callback overlay(TUI.state, overlay_cfg) :: DTask.TUI.Overlay.t
  @callback stateful_id :: atom

  @fixed_width 4
  @magic_number 2

  @title_0      "[Esc]"
  @title_prefix "┤ "
  @title_suffix " ├"
  @title_attrs  [Constants.attribute(:bold)]

  defmacro __using__(_opts) do
    quote do
      # # # # # Quoted # # # # #
      import Ratatouille.View

      @behaviour TUI.Render
      @behaviour TUI.Views.Dialog

      @impl TUI.Render
      @spec render(TUI.state) :: Element.t()
      def render(state) do
        dialog_width = TUI.Overlay.width(state, __MODULE__.stateful_id) - unquote(@fixed_width)
        title = case __MODULE__.title(state) do
          ""   -> ""
          txt  ->
            title_0 = unquote(@title_prefix) <> txt <> unquote(@title_suffix)
            free_space = dialog_width - String.length(title_0)
            fill_l = String.duplicate("─", round(free_space / 2) - unquote(@magic_number))

            fill_l <> title_0
        end
        buttons = __MODULE__.buttons(state) |> Enum.map(fn
          {txt, style} -> text([{:content, txt} | style])
          txt          -> text(content: txt)
        end)
        buttons_bar = if buttons != [] do
          buttons_width = Stream.map(buttons, &(String.length &1.attributes.content))
                          |> Enum.sum
          free_space = dialog_width - buttons_width
          fill = round(free_space / (length(buttons) + 1))
          text_i = text(content: String.duplicate(" ", fill))
          buttons_i = Enum.intersperse(buttons, text_i)

          label do
            [text_i] ++ buttons_i ++ [text_i]
          end
        end

        panel(title: unquote(@title_0), height: :fill) do
          panel(title: title, height: :fill, attributes: unquote(@title_attrs)) do
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

      defoverridable title: 1, body: 1, buttons: 1
      # # # # # End Quoted # # # # #
    end
  end

end
