defmodule DTask.TUI.Overlay do
  @moduledoc false

  alias DTask.TUI

  import DTask.Util.Syntax, only: [<|>: 2]

  use StructAccess

  @enforce_keys [:id, :render]
  defstruct     [:id, :render, :cfg, :padding, :stateful]

  @type t :: %__MODULE__{
               id: atom,
               render: TUI.Render.t,
               cfg: %{atom => term} | nil,
               padding: non_neg_integer | nil,
               stateful: TUI.Views.Stateful.t | nil
             }

  @spec open(TUI.State.t, t) :: TUI.State.t
  def open(state, overlay) when is_nil(state.ui.overlay),
      do: put_in(state.ui.overlay, overlay)

  @spec close(TUI.State.t) :: TUI.State.t
  def close(state),
      do: put_in(state.ui.overlay, nil)

  # TODO
  @spec width(TUI.State.t) :: non_neg_integer
  def width(state), do: state.ui.window.width - 2 * (state.ui.overlay.padding <|> 0)
end
