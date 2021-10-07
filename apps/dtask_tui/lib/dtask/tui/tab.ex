defmodule DTask.TUI.Tab do
  @moduledoc false

  alias DTask.TUI.Render

  @enforce_keys [:id, :shortcuts, :data_key, :render_main]
  defstruct     [:id, :shortcuts, :data_key, :render_main, :render_side, :count_data]

  @type t :: %__MODULE__{
               id: atom,
               shortcuts: [char],
               data_key: atom,
               render_main: Render.t,
               render_side: Render.t | nil,
               count_data: (term -> non_neg_integer) | nil
             }

end
