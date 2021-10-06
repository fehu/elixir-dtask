defmodule DTask.TUI do
  @moduledoc false

  alias DTask.TUI.{State, Update, Views}

  alias Ratatouille.Constants
  alias Ratatouille.Renderer.Element
  alias Ratatouille.Runtime.{Command, Subscription}

  @behaviour Ratatouille.App

  @type state :: State.t

  @type msg :: term

  @app_name :dtask_tui

  @default_tab          :executors
  @default_tab_data_key :resource_usage

  @default_show_help true
  @layout_wide_threshold 120
  @default_wide_layout   {:split_vertical, {7, 5}}
  # TODO: dynamic, depending on window height
  @default_narrow_layout {:split_horizontal, {10, :fill}}

  @tick_millis 1_000

  @key_arrow_up    Constants.key(:arrow_up)
  @key_arrow_down  Constants.key(:arrow_down)
  @key_arrow_left  Constants.key(:arrow_left)
  @key_arrow_right Constants.key(:arrow_right)
  @key_home        Constants.key(:home)
  @key_end         Constants.key(:end)

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
        const_height_f: &Views.MainView.const_height/1,
        tab: @default_tab,
        table: %State.UI.Table{
          data_key: @default_tab_data_key
        },
        show_help: @default_show_help
      }
    }
  end

  # # # Update # # #

  # Handle resize

  @impl true
  @spec update(state, msg) :: state | {state, Command.t()}
  def update(state, {:resize, event}) do
    # TODO: update :split_horizontal layout
    put_in(state.ui.window, %{height: event.h, width: event.w})
  end

  # Request data refresh on :tick

  @impl true
  def update(state, :tick) do
    cmd = Command.batch([
      Update.request_refresh(:tasks),
      Update.request_refresh(:resource_usage)
    ])
    {state, cmd}
  end

  # Refresh data

  @impl true
  def update(state, {{:refreshed, key}, data}) do
    state |> put_in([:data, key], data)
  end

  # Events
  def update(state, {:event, event}) do
    case event do
      # Move cursor
      %{key: @key_arrow_up}    -> state |> Update.move_cursor(:y, :-)
      %{key: @key_arrow_down}  -> state |> Update.move_cursor(:y, :+)
      %{key: @key_arrow_left}  -> state |> Update.move_cursor(:x, :-)
      %{key: @key_arrow_right} -> state |> Update.move_cursor(:x, :+)
      %{key: @key_home}        -> state |> Update.move_cursor(:y, 0)    |> Update.move_cursor(:x, 0)
      %{key: @key_end}         -> state |> Update.move_cursor(:y, :max) |> Update.move_cursor(:x, 0)
      _                        -> state
    end
  end

  @impl true
  def update(state, _msg) do
    # raise "UPDATE: #{inspect msg}"
    state
  end

  # Send :tick event periodically

  @impl true
  @spec subscribe(state) :: Subscription.t()
  def subscribe(_) do
    Subscription.interval(@tick_millis, :tick)
  end

  # # # Render # # #

  @impl true
  @spec render(state) :: Element.t
  defdelegate render(state), to: Views.MainView

end
