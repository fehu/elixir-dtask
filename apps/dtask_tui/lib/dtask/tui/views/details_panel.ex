defmodule DTask.TUI.Views.DetailsPanel do
  @moduledoc false

  alias DTask.TUI
  alias DTask.TUI.Render.Dimensions
  alias DTask.TUI.Views.MainView

  use DTask.TUI.Render.Details,
      dimensions: MainView.SideDimensions

  @impl true
  @spec render_details(TUI.state, term, Dimensions.t) :: Element.t
  defdelegate render_details(state, x, dimensions), to: __MODULE__, as: :render_inspect
end