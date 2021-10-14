defmodule DTask.TUI.Views.TabsBar do
  @moduledoc false

  alias Ratatouille.Constants
  import Ratatouille.View

  @behaviour DTask.TUI.Render

  @entries [
    {:separator,      " "},
    {:executors,      "[E]xecutors"},
    {:separator,      ", "},
    {:tasks_all,      "[T]asks"}
#    {:separator,      ": "},
#    {:tasks_running,  "[R]unning"},
#    {:separator,      " / "},
#    {:tasks_finished, "[F]inished"},
#    {:separator,      " / "},
#    {:tasks_pending,  "[P]ending"},
#    {:separator,      ", "},
#    {:new_task,       "[N]ew"}
  ]

  @active_style [attributes: [Constants.attribute(:bold)]]

  @impl true
  @spec render(TUI.state) :: Element.t
  def render(state) do
    bar do
      label do
        for {id, txt} <- @entries do
          style = if id == state.ui.tab.id, do: @active_style, else: []
          text([{:content, txt} | style])
        end
      end
    end
  end

end
