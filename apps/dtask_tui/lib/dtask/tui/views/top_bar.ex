defmodule DTask.TUI.Views.TopBar do
  @moduledoc false

  alias DTask.TUI

  import Ratatouille.View

  @title " DTask: "
  @title_width 8

  @conn_arrow " ⇆ "
  @conn_arrow_width 3

  @toggle_help "Help: [?] / [F1]"
  @toggle_help_width 16

  @static_width @title_width + @conn_arrow_width + @toggle_help_width

  @spec render(TUI.state) :: Element.t
  def render(state) do
    this_node_str = Atom.to_string(state.connection.this_node)
    ctrl_node_str = Atom.to_string(state.connection.ctrl_node)

    this_node_width = String.length(this_node_str)
    ctrl_node_width = String.length(ctrl_node_str)
    total_width = @static_width + this_node_width + ctrl_node_width

    empty_space = state.ui.window.width - total_width
    filler = if empty_space > 0,
                do: String.duplicate(" ", empty_space),
                else: ""

    this_node_color = if state.connection.this_node_up,
                         do: :yellow,
                         else: :red
    ctrl_node_color = if state.connection.connected,
                         do: :yellow,
                         else: :red

    toggle_help_style = if state.ui.show_help,
                           do: [:bold],
                           else: []
    bar do
      label do
        text(content: @title, attributes: [:bold])
        text(content: this_node_str, color: this_node_color)
        text(content: @conn_arrow, attributes: [:bold])
        text(content: ctrl_node_str, color: ctrl_node_color)
        text(content: filler)
        text(content: @toggle_help, attributes: toggle_help_style)
      end
    end
  end

end
