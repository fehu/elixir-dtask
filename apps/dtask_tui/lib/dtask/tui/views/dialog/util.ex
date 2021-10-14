defmodule DTask.TUI.Views.Dialog.Util do
  @moduledoc false

  alias DTask.TUI

  @spec get_cfg!(atom, atom, term | nil) :: (TUI.state -> term | no_return)
  def get_cfg!(stateful_id, key, default), do: fn state ->
    val = TUI.Overlay.find(state, stateful_id).cfg[key]
    unless is_nil(val) do
      val
    else
      if is_nil(default),
         do: raise("Undefined #{key}"),
         else: default
    end
  end

end
