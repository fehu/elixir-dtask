### TODO: WIP ###

defmodule DTask.TUI.Views.HelpPanel do
  @moduledoc false

  import Ratatouille.View

  @behaviour DTask.TUI.Render

  @layouts [
    {:split_horizontal, "[H]orizontal"},
    {:split_vertical,   "[V]ertical"},
    {:table_only,       "[W]ide"}
  ]

  @active_style [attributes: [:bold]]

#  @table_help_entries [
#    "↑",
#    "↓",
#    "←",
#    "→",
#    "PgUp",
#    "PgDown",
#    "Home",
#    "End"
#  ]

  @table_help "Table: [↑] / [↓] / [←] / [→] / [PageUp] / [PageDown] / [Home] / [End] / [Enter]"

  @height 6

  def height(state) do
    case state.ui.layout do
      :table_only -> @height - 1
      _           -> @height
    end
  end

  @impl true
  @spec render(TUI.state) :: Element.t
  def render(state) do
    panel(title: "Help") do
      view_help(state.ui)
      layout_help(state.ui)
      label(content: @table_help)
    end
  end

  defp view_help(state_ui) do
    layout_help_entries =
      for {id, txt} <- @layouts do
        active? = case state_ui.layout do
          {layout, _} -> layout == id
          layout      -> layout == id
        end
        style = if active?,
                   do: @active_style,
                   else: []
        text([{:content, txt} | style])
      end
    label do
      text(content: "View: ")
      Enum.intersperse(layout_help_entries, text(content: " / "))
    end
  end

  defp layout_help(state_ui) when is_tuple(state_ui.layout) do
    # label(content: "Layout: TODO")
    label do
      text(content: "Layout: ")
      text(content: "[", attributes: [:bold])
      text(content: "{", attributes: [:underline])
      text(content: "]", attributes: [:bold])
    end
  end
  defp layout_help(state_ui),
       do: nil

#  defp table_help(state) do
#    navigate = @table_help_entries
#               |> Stream.map("[#{&1}]")
#               |> Enum.intersperse(" / ")
#    label(content: "Table: #{navigate}. Details: [Enter]")
#  end

end
