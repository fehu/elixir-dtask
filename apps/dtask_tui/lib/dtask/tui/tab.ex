defmodule DTask.TUI.Tab do
  @moduledoc false

  alias DTask.TUI.Render

  @enforce_keys [:id, :shortcuts, :data_key, :render_main]
  defstruct     [:id, :shortcuts, :data_key, :render_main, :render_side]

  @type t :: %__MODULE__{
               id: atom,
               shortcuts: [char],
               data_key: atom,
               render_main: Render.t,
               render_side: Render.t | nil
             }

end
