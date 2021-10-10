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
  *==============================================================================*  ─────
  | +-|<table>|----------------------------------------------------------------+ |    ↑
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │ main
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | +--------------------------------------------------------------------------+ |    ↓
  *==============================================================================*  ─────
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
  *==============================================================================*  ─────
  | +-|<table>|----------------------------------------------------------------+ |    ↑
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │ main
  | +--------------------------------------------------------------------------+ |    │
  | +-|<details>|--------------------------------------------------------------+ |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | |                                                                          | |    │
  | +--------------------------------------------------------------------------+ |    ↓
  *==============================================================================*  ─────
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
  *==============================================================================*  ─────
  | +-|<table>|-------------------------------------+ +-|<details>|------------+ |    ↑
  | |                                               | |                        | |    │
  | +-----------------------------------------------+ |                        | |    │
  | |                                               | |                        | |    │
  | +-----------------------------------------------+ |                        | |    │
  | |                                               | |                        | |    │
  | +-----------------------------------------------+ |                        | |    │
  | |                                               | |                        | |    │ main
  | +-----------------------------------------------+ |                        | |    │
  | |                                               | |                        | |    │
  | +-----------------------------------------------+ |                        | |    │
  | |                                               | |                        | |    │
  | +-----------------------------------------------+ |                        | |    │
  | |                                               | |                        | |    │
  | +-----------------------------------------------+ +------------------------+ |    ↓
  *==============================================================================*  ─────
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
  @height_extra      &Views.HelpPanel.height/1

  @const_table_height 5

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
    if state.ui.show_help, do: height0 + @height_extra.(state), else: height0
  end

  @spec main_height(TUI.state) :: pos_integer
  def main_height(state) do
    state.ui.window.height - const_height(state)
  end

  @spec table_height(TUI.state) :: pos_integer
  def table_height(state) do
    table_rows(state) + @const_table_height
  end

  @spec table_height_and_rows(TUI.state) :: {pos_integer, pos_integer}
  def table_height_and_rows(state) do
    rows = table_rows(state)
    {rows + @const_table_height, rows}
  end

  # TODO
  @spec details_height(TUI.state) :: pos_integer
  def details_height(state) do
    case state.ui.layout do
      {:split_horizontal, ratio} -> main_height(state) * (1 - ratio)
      _                          -> main_height(state)
    end
  end

  @spec table_rows(TUI.state) :: pos_integer
  def table_rows(state) do
    case state.ui.layout do
      {:split_horizontal, ratio} -> max(round(main_height(state) * ratio), 1)
      _                          -> main_height(state) - @const_table_height
    end
  end

  @spec main_width(TUI.state) :: pos_integer
  def main_width(state), do: state.ui.window.width

  @spec table_width(TUI.state) :: pos_integer
  def table_width(state), do: do_width(state, 0)

  @spec details_width(TUI.state) :: pos_integer
  def details_width(state), do: do_width(state, 1)

  defp do_width(state, index) do
    case state.ui.layout do
      {:split_vertical, g_width} -> round(state.ui.window.width * (elem(g_width, index)  / @grid_size))
      _                          -> state.ui.window.width
    end
  end

  defmodule TableCursor do
    use Views.Stateful.Cursor

    @spec max_y_view(TUI.state) :: non_neg_integer
    defdelegate max_y_view(state), to: Views.MainView, as: :table_rows
  end
end
