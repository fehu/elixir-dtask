defmodule DTask.TUI.Tab do
  @moduledoc false

  alias DTask.TUI
  alias DTask.TUI.Render
  alias DTask.TUI.Views.Stateful

  use StructAccess

  @enforce_keys [:id, :shortcuts, :data_key, :render_main]
  defstruct     [:id, :shortcuts, :data_key, :render_main, :render_side, :stateful]

  @type t :: %__MODULE__{
               id: atom,
               shortcuts: [char],
               data_key: atom,
               render_main: Render.t,
               render_side: Render.t | nil,
               stateful: Stateful.t | [module] | nil
             }

  # # # Build helpers # # #

  @spec init(t | TUI.State.t) :: t | TUI.State.t
  def init(state) when is_struct(state, TUI.State) do
    update_in(state.ui.tab, &init/1)
  end
  def init(tab) when is_struct(tab, __MODULE__) do
    update_in tab.stateful, fn
      []                            -> nil
      mods when is_list(mods)       -> Stateful.create_many(mods)
      s when is_struct(s, Stateful) -> s
      _                             -> nil
    end
  end

  # # # Access helpers # # #

  @spec cursor(TUI.state, axis) :: non_neg_integer | nil
                                when axis: :x | :y
  def cursor(state, axis) when not is_nil(state.ui.tab.stateful)
                           and not is_nil(state.ui.tab.stateful.state.cursor)
                           and axis in [:x, :y],
      do: state.ui.tab.stateful.state.cursor[axis]
  def cursor(_, _), do: nil
end
