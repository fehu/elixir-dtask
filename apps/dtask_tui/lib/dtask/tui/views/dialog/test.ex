defmodule DTask.TUI.Views.Dialog.Test do
  @moduledoc false

  alias DTask.TUI

  import Ratatouille.View

  @behaviour TUI.Render

  @impl true
  def render(state) do
    panel(title: "Test") do

    end
  end

end
