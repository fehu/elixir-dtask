defmodule DTask.TUI do
  @moduledoc false

  alias DTask.{ResourceUsage, Task}

  alias DTask.TUI.Util.Render
  alias DTask.TUI.Util.TableDetailsView
  alias DTask.TUI.Util.TestPanel

  alias Ratatouille.Renderer.Element
  alias Ratatouille.Runtime.Command

  import Ratatouille.View

  @behaviour Ratatouille.App

  @typep tab :: :executors
              | :tasks_all
              | :tasks_finished
              | :tasks_pending
              | :tasks_running
  @typep layout :: TableDetailsView.mode
#  @typep layout :: :narrow | :wide

  # TODO: refactor
  @type model :: %{
                   this_node: node,
                   ctrl_node: node,
                   window_width: non_neg_integer,
                   layout: layout,
                   tab: tab,
                   show_help: boolean,
                   show_tabs: boolean,
                   tasks: Task.Monitor.state,
                   resource_usage: ResourceUsage.Collector.usage
                 }

  @type msg :: term

  @default_tab :executors
  @default_show_help true
  @default_show_tabs true
  @layout_wide_threshold 120
  @default_wide_layout   {:split_vertical, {7, 5}}
  # TODO: dynamic, depending on window height
  @default_narrow_layout {:split_horizontal, {10, :fill}}
  

  @grid_size 12

  @impl true
  @spec init(map()) :: model | {model, Command.t()}
  def init(context) do
#    tasks = Task.Monitor.get_state
#    resource_usage = ResourceUsage.Collector.get_usage
    tasks = nil
    resource_usage = nil
    layout = if context.window.width > @layout_wide_threshold,
                do: @default_wide_layout,
                else: @default_narrow_layout
    %{
      this_node: :this@test,
      ctrl_node: :ctrl@test,
      window_width: context.window.width,
      layout: layout,
      tab: @default_tab,
      show_help: @default_show_help,
      show_tabs: @default_show_tabs,
      tasks: tasks,
      resource_usage: resource_usage
    }
  end

  @impl true
  @spec update(model, msg) :: model | {model, Command.t()}
  def update(model, {:resize, event}),
      do: %{model | :window_width => event.w}
  def update(model, msg) do
    # raise "UPDATE: #{inspect msg}"
    model
  end

  # @impl true
  # TODO: @spec subscribe(model) :: Subscription.t()


  @impl true
  @spec render(model) :: Element.t
  def render(model) do
    view = %TableDetailsView {
      top_bar: render_top_bar(model),
      extra: render_help_panel(model),
      table: %TestPanel{title: "Table"},
      details: %TestPanel{title: "Details"},
      bottom_bar: render_bottom_bar(model)
    }
#    mode = :table_only
#    mode = {:split_vertical, {7, 5}}
#    mode = {:split_horizontal, {20, :fill}}
    Render.render(view, model, model.layout)
  end

  @title " DTask: "
  @title_width 8

  @conn_arrow " ⇆ "
  @conn_arrow_width 3

  @toggle_help "Help: [?] / [F1]"
  @toggle_help_width 16

  @menu_entries [
    {:separator,      " "},
    {:executors,      "[E]xecutors"},
    {:separator,      ", "},
    {:tasks_all,      "[T]asks"},
    {:separator,      ": "},
    {:tasks_running,  "[R]unning"},
    {:separator,      " / "},
    {:tasks_finished, "[F]inished"},
    {:separator,      " / "},
    {:tasks_pending,  "[P]ending"},
    {:separator,      ", "},
    {:new_task,       "[N]ew"}
  ]

  @view_modes [
    {:horizontal, "[H]orizontal"},
    {:vertical,   "[V]ertical"},
    {:wide,       "[W]ide"}
  ]
  
  @active_style [attributes: [:bold]]

  @arrow_left  "←"
  @arrow_right "→"
  @arrow_up    "↑"
  @arrow_down  "↓"

  @spec render_top_bar(model) :: TableDetailsView.component
  defp render_top_bar(model) do
    this_node_str = Atom.to_string(model.this_node)
    ctrl_node_str = Atom.to_string(model.ctrl_node)
    this_node_width = String.length(this_node_str)
    ctrl_node_width = String.length(ctrl_node_str)
    total_width = @title_width + this_node_width + @conn_arrow_width + ctrl_node_width + @toggle_help_width
    empty_space = model.window_width - total_width
    filler = if empty_space > 0, do: String.duplicate(" ", empty_space), else: ""

    bar do
      label do
        text(content: @title, attributes: [:bold])
        text(content: this_node_str, color: :yellow)
        text(content: @conn_arrow, attributes: [:bold])
        text(content: ctrl_node_str, color: :yellow)
        text(content: filler)
        text(content: @toggle_help)
      end
    end
  end

  defp render_bottom_bar(model) do
    bar do
      label do
        for {id, txt} <- @menu_entries do
          style = if id == model.tab, do: @active_style, else: []
          text([{:content, txt} | style])
        end
      end
    end
  end

  # TODO: should depend on current view mode
  # TODO: refactor
  defp render_help_panel(model) do
    view_entries = for {id, txt} <- @view_modes do
      style = case {id, model.layout} do
        {:horizontal, {:split_horizontal, _}} -> @active_style
        {:vertical,   {:split_vertical, _}}   -> @active_style
        {:wide,       :table_only}            -> @active_style
        _                                     -> []
      end
      text([{:content, txt} | style])
    end
    view_help = label([], [
      text(content: "View: ") | Enum.intersperse(view_entries, text(content: " / "))
    ])
    panel(title: "Help") do
      view_help
      label(content: "Details: [Enter]")
      label(content: "Resize: #{@arrow_up} [{] / [[], #{@arrow_down} [}] / []]")
      label(content: "Scroll: [#{@arrow_down}] / [#{@arrow_up}] / [#{@arrow_left}] / [#{@arrow_down}] / [PgUp] / [PgDown] / [Home] / [End]")
    end
  end

end
