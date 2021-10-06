defmodule DTask.TUI.Views.MainView do
  @moduledoc """

  ## [mode: :table_only]

  ```
  *==============================================================================*
  | <Top Bar>                                                                    |
  *==============================================================================*
  |                                                                              |
  | <Extra Bar> [Optional]                                                       |
  |                                                                              |
  *==============================================================================*
  | +-|<table>|----------------------------------------------------------------+ |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | +--------------------------------------------------------------------------+ |
  *==============================================================================*
  | <Bottom Bar>                                                                 |
  *==============================================================================*
  ```

  ## [mode: {:split_horizontal, ratio}]

  ```
  *==============================================================================*
  | <Top Bar>                                                                    |
  *==============================================================================*
  |                                                                              |
  | <Extra Bar> [Optional]                                                       |
  |                                                                              |
  *==============================================================================*
  | +-|<table>|----------------------------------------------------------------+ |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | +--------------------------------------------------------------------------+ |
  | +-|<details>|--------------------------------------------------------------+ |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | |                                                                          | |
  | +--------------------------------------------------------------------------+ |
  *==============================================================================*
  | <Bottom Bar>                                                                 |
  *==============================================================================*
  ```

  ## [mode: {:split_vertical, ratio}]

  ```
  *==============================================================================*
  | <Top Bar>                                                                    |
  *==============================================================================*
  |                                                                              |
  | <Extra Bar> [Optional]                                                       |
  |                                                                              |
  *==============================================================================*
  | +-|<table>|-------------------------------------+ +-|<details>|------------+ |
  | |                                               | |                        | |
  | +-----------------------------------------------+ |                        | |
  | |                                               | |                        | |
  | +-----------------------------------------------+ |                        | |
  | |                                               | |                        | |
  | +-----------------------------------------------+ |                        | |
  | |                                               | |                        | |
  | +-----------------------------------------------+ |                        | |
  | |                                               | |                        | |
  | +-----------------------------------------------+ |                        | |
  | |                                               | |                        | |
  | +-----------------------------------------------+ |                        | |
  | |                                               | |                        | |
  | +-----------------------------------------------+ +------------------------+ |
  *==============================================================================*
  | <Bottom Bar>                                                                 |
  *==============================================================================*
  ```
  """

  alias DTask.TUI
  alias DTask.TUI.Views

  import Ratatouille.View

  @behaviour DTask.TUI.Render

  @grid_size 12

  @render_top_bar    Views.TopBar
  @height_top_bar    1
  @render_bottom_bar Views.TabsBar
  @height_bottom_bar 1
  @render_extra      Views.HelpPanel
  @height_extra      Views.HelpPanel.height


  @impl true
  @spec render(TUI.state) :: Element.t()
  def render(state) do
    view_opts = [
      top_bar: @render_top_bar.render(state),
      bottom_bar: @render_bottom_bar.render(state)
    ]
    extra = if state.ui.show_help,
               do: [
                 row do
                   column(size: @grid_size) do
                     @render_extra.render(state)
                   end
                 end
               ],
               else: []
    main = case {state.ui.layout, state.ui.tab.render_side} do
      {layout, render_side} when layout == :table_only or is_nil(render_side) -> [
        row do
          column(size: @grid_size) do
            state.ui.tab.render_main.render(state)
          end
        end
      ]
      {{:split_horizontal, _}, render_side} -> [
        row do
          column(size: @grid_size) do
            state.ui.tab.render_main.render(state)
          end
        end,
        row do
          column(size: @grid_size) do
            render_side.render(state)
          end
        end
      ]
      {{:split_vertical, {size_left, size_right}}, render_side} -> [
        row do
          column size: size_left do
            state.ui.tab.render_main.render(state)
          end
          column size: size_right do
            render_side.render(state)
          end
        end
      ]
    end
    view(view_opts, extra ++ main)
  end

  @spec const_height(TUI.state) :: non_neg_integer
  def const_height(state) do
    height0 = @height_top_bar + @height_bottom_bar
    if state.ui.show_help, do: height0 + @height_extra, else: height0
  end
end
