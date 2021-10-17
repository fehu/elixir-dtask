defmodule DTask.TUI.Render.Dimensions do
  @moduledoc false

  @type t :: module

  alias DTask.TUI

  @callback height(TUI.state) :: non_neg_integer
  @callback width(TUI.state) :: non_neg_integer

end
