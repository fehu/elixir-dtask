defmodule DTask.TUI do
  @moduledoc false


  alias DTask.TUI.Util.Render
  alias DTask.TUI.Util.TableDetailsView
  alias DTask.TUI.Util.TestPanel
  alias DTask.TUI.{State, Update, Views}

  alias Ratatouille.Renderer.Element
  alias Ratatouille.Runtime.{Command, Subscription}

  @behaviour Ratatouille.App

  @type state :: State.t

  @type msg :: term

  @app_name :dtask_tui

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
    cfg = Enum.into(Application.get_all_env(@app_name), %{})

    # State.Connection

    ctrl_node = Map.get(cfg, :master_node)
    connected = Node.ping(ctrl_node) == :pong

    # State.UI

    layout = if context.window.width > @layout_wide_threshold,
                do: @default_wide_layout,
                else: @default_narrow_layout

    # State

    %State{
      connection: %State.Connection{
        this_node: Node.self(),
        this_node_up: Node.alive?,
        cookie: Map.get(cfg, :cookie),
        ctrl_node: ctrl_node,
        connected: connected
      },
      data: %State.Data{},
      ui: %State.UI{
        window: context.window,
        layout: layout,
        active_tab: @default_tab,
        table: %State.UI.Table{},
        show_tabs: @default_show_tabs,
        show_help: @default_show_help
      }
    }
  end

  @impl true
  @spec update(state, msg) :: state | {state, Command.t()}
  def update(state, {:resize, event}) do
    put_in(state.ui.window, %{height: event.h, width: event.w})
  end

  @impl true
  def update(state, :tick) do
    cmd = Command.batch([
      Update.request_refresh(:tasks),
      Update.request_refresh(:resource_usage)
    ])
    {state, cmd}
  end

  @impl true
  def update(state, {{:refreshed, key}, data}) do
    state |> put_in([:data, key], data)
  end

  @impl true
  def update(state, _msg) do
    # raise "UPDATE: #{inspect msg}"
    state
  end

  @impl true
  @spec subscribe(state) :: Subscription.t()
  def subscribe(_) do
    Subscription.interval(1_000, :tick)
  end


  @impl true
  @spec render(state) :: Element.t
  def render(state) do
    view = %TableDetailsView {
      top_bar: Views.TopBar.render(state),
      extra: Views.HelpPanel.render(state),
      table: Views.Executors.render_table(state),
      details: %TestPanel{title: "Details"},
      bottom_bar: Views.TabsBar.render(state)
    }
#    mode = :table_only
#    mode = {:split_vertical, {7, 5}}
#    mode = {:split_horizontal, {20, :fill}}
    Render.render(view, state, state.ui.layout)
  end

end
