defmodule DTask.TUI.Views.Dialog.Test do
  @moduledoc false

  alias DTask.TUI

  use TUI.Views.Dialog
  # Implements
  # @behaviour TUI.Render
  # @behaviour TUI.Views.Dialog

  @impl true
  @spec title(TUI.state) :: String.t
  def title(_), do: "Test"

  @impl true
  @spec body(TUI.state) :: [Element.t]
  def body(_) do
    [label(content: "!!!")]
  end

end
