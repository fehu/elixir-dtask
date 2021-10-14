defmodule DTask.TUI.Overlay do
  @moduledoc false

  alias DTask.TUI

  import DTask.Util.Syntax, only: [<|>: 2, maybe: 2]

  use StructAccess

  @enforce_keys [:id, :render, :padding]
  defstruct     [:id, :render, :padding, :cfg, :stateful]

  @type t :: %__MODULE__{
               id: atom,
               render: TUI.Render.t,
               padding: non_neg_integer,
               cfg: %{atom => term} | nil,
               stateful: TUI.Views.Stateful.t | nil
             }

  @overlays_k [:ui, :overlays]

  @spec open(TUI.State.t, t) :: TUI.State.t
  def open(state, overlay),
      do: state |> update_in(@overlays_k, &[overlay | &1])
                |> TUI.State.put_active_ui(@overlays_k)

  @spec close(TUI.State.t) :: TUI.State.t
  def close(state) when state.ui.overlays != [],
      do: state |> TUI.State.pop_active_ui(hd state.ui.overlays)
                |> update_in(@overlays_k, &tl/1)

  @spec find(TUI.State.t, atom) :: TUI.Overlay.t | nil
  def find(state, overlay_id), do: Enum.find(state.ui.overlays, &(&1.id == overlay_id))

  @spec width(TUI.State.t, atom) :: non_neg_integer
  def width(state, overlay_id), do:
    state.ui.window.width - 2 * (maybe(find(state, overlay_id), &(&1.padding)) <|> 0)
end
