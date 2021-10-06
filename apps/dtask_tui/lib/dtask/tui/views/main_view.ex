defmodule DTask.TUI.MainView do
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
  @render_bottom_bar Views.TabsBar
  @render_extra      Views.HelpPanel

  @render_main %{
    executors: {Views.ExecutorsTable, Views.DetailsPanel}
  }
  @render_table   @render_main |> Enum.map(fn {k, {v, _}} -> {k, v} end)
  @render_details @render_main |> Enum.map(fn {k, {_, v}} -> {k, v} end)

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
    main = case state.ui.layout do
      :table_only -> [
        row do
          column(size: @grid_size) do
            @render_table[state.ui.active_tab].render(state)
          end
        end
      ]
      {:split_horizontal, _} -> [
        row do
          column(size: @grid_size) do
            @render_table[state.ui.active_tab].render(state)
          end
        end,
        row do
          column(size: @grid_size) do
            @render_details[state.ui.active_tab].render(state)
          end
        end
      ]
      {:split_vertical, {size_left, size_right}} -> [
        row do
          column size: size_left do
            @render_table[state.ui.active_tab].render(state)
          end
          column size: size_right do
            @render_details[state.ui.active_tab].render(state)
          end
        end
      ]
    end
    view(view_opts, extra ++ main)
  end
end
