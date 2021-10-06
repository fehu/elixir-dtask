defmodule DTask.TUI.Views.DetailsPanel do
  @moduledoc false

  alias DTask.TUI

  import Ratatouille.View

  @behaviour DTask.TUI.Render

  ### TODO

  @impl true
  @spec render(TUI.state) :: Element.t
  def render(state) when state.ui.layout != :table_only do
    height = case state.ui.layout do
      {:split_horizontal, {_, h}} -> h
      {:split_vertical, _}        -> :fill
    end
    panel title: "Details", height: height do
      label(content: "=== TODO ===")
    end
  end
end
