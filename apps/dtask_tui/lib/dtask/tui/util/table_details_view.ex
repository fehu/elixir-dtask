alias DTask.TUI.Util.Render

defmodule DTask.TUI.Util.TableDetailsView do
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

  @enforce_keys [:table, :details]
  defstruct [:top_bar, :extra, :table, :details, :bottom_bar]

  @typep pos_int_2 :: {pos_integer, pos_integer}
  @type mode :: :table_only
              | {:split_horizontal, heights :: pos_int_2}
              | {:split_vertical, ratio :: pos_int_2}

  @type component :: Render.t | Ratatouille.Renderer.Element.t

  @type t :: %__MODULE__{
               top_bar:    component | nil,
               extra:      component | nil,
               table:      component,
               details:    component,
               bottom_bar: component | nil
             }
end

alias DTask.TUI.Util.TableDetailsView

defimpl Render, for: TableDetailsView do
  import Ratatouille.View

  @grid_size 12

  @spec render(TableDetailsView.t, term, TableDetailsView.mode) :: Element.t
  def render(t, model, mode) do
    view_opts = [
      top_bar: maybe_render(t.top_bar, model, nil),
      bottom_bar: maybe_render(t.bottom_bar, model, nil)
    ]
    extra = case maybe_render(t.extra, model, nil) do
      nil -> []
      e -> [
        row do
          column(size: @grid_size) do
            e
          end
        end
      ]
    end
    main = case mode do
      :table_only -> [
        row do
          column(size: @grid_size) do
            maybe_render(t.table, model, nil)
          end
        end
      ]
      {:split_horizontal, {height_top, height_bottom}} -> [
        row do
          column(size: @grid_size) do
            maybe_render(t.table, model, height: height_top)
          end
        end,
        row do
          column(size: @grid_size) do
            maybe_render(t.details, model, height: height_bottom)
          end
        end
      ]
      {:split_vertical, {size_left, size_right}} -> [
        row do
          column size: size_left do
            maybe_render(t.table, model, nil)
          end
          column size: size_right do
            maybe_render(t.details, model, nil)
          end
        end
      ]
    end
    view(view_opts, extra ++ main)
  end

  @spec maybe_render(TableDetailsView.component | nil, model :: term, opts :: term) :: Element.t | nil
  defp maybe_render(t, _, _) when is_struct(t, Ratatouille.Renderer.Element),
       do: t
  defp maybe_render(nil, _, _),
       do: nil
  defp maybe_render(t, model, opts) do
    case Render.impl_for(t) do
      nil  -> nil
      impl -> impl.render(t, model, opts)
    end
  end
end
