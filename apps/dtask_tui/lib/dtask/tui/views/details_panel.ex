defmodule DTask.TUI.Views.DetailsPanel do
  @moduledoc false

  alias DTask.TUI

  use DTask.TUI.Render.Details

  @impl true
  @spec render_details(TUI.state, term) :: Element.t
  def render_details(_, x), do: render_inspect(x)
end