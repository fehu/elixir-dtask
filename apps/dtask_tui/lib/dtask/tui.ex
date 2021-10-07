defmodule DTask.TUI do
  @moduledoc false

  alias DTask.TUI.{State, Update, Views}
  alias DTask.TUI.Tab

  alias Ratatouille.Constants
  alias Ratatouille.Renderer.Element
  alias Ratatouille.Runtime.{Command, Subscription}

  @behaviour Ratatouille.App

  @type state :: State.t

  @type msg :: term

  @app_name :dtask_tui

  @tabs [
    %Tab{
      id: :executors,
      data_key: Views.ExecutorsTable.data_key,
      shortcuts: [?e, ?E],
      render_main: Views.ExecutorsTable,
      render_side: Views.ExecutorDetails
    },
    %Tab{
      id: :tasks_all,
      data_key: Views.TasksTable.data_key,
      shortcuts: [?t, ?T],
      render_main: Views.TasksTable,
      render_side: Views.DetailsPanel,
      count_data: &Views.TasksTable.count_data/1
    },
    %Tab{
      id: :tasks_running,
      data_key: Views.TestTable.data_key,
      shortcuts: [?r, ?R],
      render_main: Views.TestTable,
      render_side: Views.DetailsPanel
    },
    %Tab{
      id: :tasks_finished,
      data_key: Views.TestTable.data_key,
      shortcuts: [?f, ?F],
      render_main: Views.TestTable,
      render_side: Views.DetailsPanel
    },
    %Tab{
      id: :tasks_pending,
      data_key: Views.TestTable.data_key,
      shortcuts: [?p, ?P],
      render_main: Views.TestTable,
      render_side: Views.DetailsPanel
    },
    %Tab{
      id: :new_task,
      data_key: Views.TestTable.data_key,
      shortcuts: [?n, ?N],
      render_main: Views.TestTable
    }
  ]

  @tabs_map     @tabs |> Enum.map(&{&1.id, &1}) |> Map.new
  @tab_keys_map @tabs |> Enum.flat_map(fn tab -> tab.shortcuts |> Enum.map(&{&1, tab}) end) |> Map.new
  @tab_keys     Map.keys(@tab_keys_map)

  @default_tab @tabs_map[:executors]

  @default_show_help true

  @default_horizontal_layout {:split_horizontal, 0.5}
  @default_vertical_layout   {:split_vertical, {7, 5}}

  @layout_wide_threshold 120
  @default_wide_layout   @default_vertical_layout
  @default_narrow_layout @default_horizontal_layout

  @layout_keys_map %{
    ?h => @default_horizontal_layout,
    ?H => @default_horizontal_layout,
    ?v => @default_vertical_layout,
    ?V => @default_vertical_layout,
    ?w => :table_only,
    ?W => :table_only
  }
  @layout_keys Map.keys(@layout_keys_map)

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

    # Disable logger
    Logger.configure(level: :error)

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
      data: %State.Data{
        resource_usage_hist_limit: cfg.resource_usage_hist_limit,
        test: Enum.to_list(1..100)
      },
      ui: %State.UI{
        window: context.window,
        layout: layout,
        const_height_f: &Views.MainView.const_height/1,
        tab: @default_tab,
        table: %State.UI.Table{},
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
    new_state_0 = state |> put_in([:data, key], data)
    if key == :resource_usage,
       do: new_state_0 |> update_resource_usage_hist(data),
       else: new_state_0
  end

  # Events
  def update(state, {:event, event}) do
    case event do
      # Move cursor
      %{key: @key_arrow_up}           -> state |> Update.move_cursor(:y, :-)
      %{key: @key_arrow_down}         -> state |> Update.move_cursor(:y, :+)
      %{key: @key_arrow_left}         -> state |> Update.move_cursor(:x, :-)
      %{key: @key_arrow_right}        -> state |> Update.move_cursor(:x, :+)
      %{key: @key_home}               -> state |> Update.move_cursor(:y, 0)    |> Update.move_cursor(:x, 0)
      %{key: @key_end}                -> state |> Update.move_cursor(:y, :max) |> Update.move_cursor(:x, 0)
      %{ch: c} when c in @tab_keys    -> state |> Update.tab(@tab_keys_map[c])
      %{ch: c} when c in @layout_keys -> state |> Update.layout(@layout_keys_map[c])
      _                               -> state
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


  # # # Private functions # # #

  defp update_resource_usage_hist(state, data) do
    update_in state.data.resource_usage_hist, fn hist ->
      tail = if length(hist) >= state.data.resource_usage_hist_limit,
                do: List.delete_at(hist, -1),
                else: hist
      [data | tail]
    end
  end
end
