defmodule DTask.TUI.Views.DetailsPanel do
  @moduledoc false

  alias DTask.TUI

  import Ratatouille.View

  @behaviour DTask.TUI.Render

  ### TODO

  @impl true
  @spec render(TUI.state) :: Element.t
  def render(state) when state.ui.layout != :table_only do
    panel title: "Details", height: :fill do
      label(content: "=== TODO ===")
    end
  end
end
