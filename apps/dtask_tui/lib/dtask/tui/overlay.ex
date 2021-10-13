defmodule DTask.TUI.Overlay do
  @moduledoc false

  alias DTask.TUI

  import DTask.Util.Syntax, only: [<|>: 2, maybe: 2]

  use StructAccess

  @enforce_keys [:id, :render]
  defstruct     [:id, :render, :cfg, :stateful]

  @type t :: %__MODULE__{
               id: atom,
               render: TUI.Render.t,
               cfg: %{atom => term} | nil,
               stateful: TUI.Views.Stateful.t | nil
             }

  @fixed_width 10 * 2
  @state_keys [:ui, :overlay]

  @spec open(TUI.State.t, t) :: TUI.State.t
  def open(state, overlay) when is_nil(state.ui.overlay),
      do: state |> put_in(@state_keys, overlay)
                |> TUI.State.put_active_ui(@state_keys)

  @spec close(TUI.State.t) :: TUI.State.t
  def close(state) when not is_nil(state.ui.overlay),
      do: state |> TUI.State.pop_active_ui(state.ui.overlay)
                |> put_in(@state_keys, nil)

  @spec width(TUI.State.t) :: non_neg_integer
  def width(state), do: state.ui.window.width - @fixed_width
end
