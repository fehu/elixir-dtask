defmodule DTask.TUI do
  @moduledoc false


  alias DTask.TUI.Util.Render
  alias DTask.TUI.Util.TableDetailsView
  alias DTask.TUI.Util.TestPanel
  alias DTask.TUI.{State, Views}

  alias Ratatouille.Renderer.Element
  alias Ratatouille.Runtime.Command

  @behaviour Ratatouille.App

  @type state :: State.t

  @type msg :: term

  @default_tab :executors
  @default_show_help true
  @default_show_tabs true
  @layout_wide_threshold 120
  @default_wide_layout   {:split_vertical, {7, 5}}
  # TODO: dynamic, depending on window height
  @default_narrow_layout {:split_horizontal, {10, :fill}}
  

  @impl true
  @spec init(map()) :: state | {state, Command.t()}
  def init(context) do
#    tasks = Task.Monitor.get_state
#    resource_usage = ResourceUsage.Collector.get_usage
    layout = if context.window.width > @layout_wide_threshold,
                do: @default_wide_layout,
                else: @default_narrow_layout
    %State{
      # TODO =======================
      connection: %State.Connection{
        this_node: :this@todo,
        this_node_up: true,
        ctrl_node: :ctrl@todo,
        connected: false
      },
      data: %State.Data{},
      ui: %State.UI{
        window: context.window,
        layout: layout,
        active_tab: @default_tab,
        show_tabs: true,
        show_help: true
      }
    }
  end

  @impl true
  @spec update(state, msg) :: state | {state, Command.t()}
  def update(state, {:resize, event}) do
    put_in(state.ui.window, %{height: event.h, width: event.w})
  end
  def update(state, _msg) do
    # raise "UPDATE: #{inspect msg}"
    state
  end

  # @impl true
  # TODO: @spec subscribe(state) :: Subscription.t()


  @impl true
  @spec render(state) :: Element.t
  def render(state) do
    view = %TableDetailsView {
      top_bar: Views.TopBar.render(state),
      extra: Views.HelpPanel.render(state),
      table: %TestPanel{title: "Table"},
      details: %TestPanel{title: "Details"},
      bottom_bar: Views.TabsBar.render(state)
    }
#    mode = :table_only
#    mode = {:split_vertical, {7, 5}}
#    mode = {:split_horizontal, {20, :fill}}
    Render.render(view, state, state.ui.layout)
  end

end
