defmodule DTask.TUI.Render.Dimensions do
  @moduledoc false

  @callback max_x_view(TUI.state) :: non_neg_integer
  @callback max_y_view(TUI.state) :: non_neg_integer
end
