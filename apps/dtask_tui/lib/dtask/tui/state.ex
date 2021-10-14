defmodule DTask.TUI.State do
  @moduledoc false

  use StructAccess

  @enforce_keys [:connection, :data, :ui]
  defstruct     [:connection, :data, :ui]

  @type connection :: __MODULE__.Connection.t
  @type data       :: __MODULE__.Data.t
  @type ui         :: __MODULE__.UI.t

  @type t :: %__MODULE__{
               connection: connection,
               data: data,
               ui: ui
             }
  # # # # # # # # # # # # # # # # # # # #

  defmodule Connection do
    use StructAccess

    @enforce_keys [:this_node, :this_node_up, :cookie, :ctrl_node, :connected]
    defstruct     [:this_node, :this_node_up, :cookie, :ctrl_node, :connected]

    @type t :: %__MODULE__{
                 this_node: node,
                 this_node_up: boolean,
                 cookie: atom | nil,
                 ctrl_node: node | nil,
                 connected: boolean
               }
  end

  # # # # # # # # # # # # # # # # # # # #

  defmodule Data do
    use StructAccess

    @enforce_keys [:resource_usage_hist_limit]
    defstruct     [:resource_usage_hist_limit, :resource_usage, :tasks, :test, resource_usage_hist: []]

    @type tasks :: [{Dispatcher.task_id, {Dispatcher.task_descriptor, Monitor.task_state}}] | nil
    @type resource_usage :: [DTask.ResourceUsage.Collector.usage_tuple] | nil

    @type t :: %__MODULE__{
                 resource_usage: resource_usage,
                 resource_usage_hist: [resource_usage],
                 resource_usage_hist_limit: non_neg_integer,
                 tasks: tasks,
                 test: [integer]
               }
  end

  # # # # # # # # # # # # # # # # # # # #

  defmodule UI do
    use StructAccess

    @enforce_keys [:window, :layout, :active_stack, :tab, :show_help]
    defstruct     [:window, :layout, :active_stack, :tab, :show_help, overlays: []]

    @typep pos_int_2 :: {pos_integer, pos_integer}

    @type window :: %{
                      height: non_neg_integer,
                      width: non_neg_integer
                    }

    @type layout :: {:split_horizontal, ratio   :: float}
                  | {:split_vertical,   heights :: pos_int_2}
                  | :table_only

    @type tab :: DTask.TUI.Tab.t

    @type t :: %__MODULE__{
                 window: window,
                 layout: layout,
                 active_stack: [[atom, ...], ...],
                 tab: tab,
                 overlays: [DTask.TUI.Overlay.t],
                 show_help: boolean
               }

  end

  @spec active_ui_keys(t) :: [atom, ...]
  def active_ui_keys(state), do: hd(state.ui.active_stack)

  @spec active_ui(t) :: term | nil
  def active_ui(state) do
    case get_in(state, active_ui_keys(state)) do
      [h | _] -> h
      other   -> other
    end
  end

  @spec update_active_ui(t, (term -> term)) :: t
  def update_active_ui(state, upd),
      do: update_in(state, active_ui_keys(state), fn
        l when is_list(l) and l != [] -> [upd.(hd l) | tl(l)]
        other -> upd.(other)
      end)

  @spec put_active_ui(t, [atom, ...]) :: t
  def put_active_ui(state, keys),
      do: update_in(state.ui.active_stack, &[keys | &1])

  @spec pop_active_ui(t, term) :: t
  def pop_active_ui(state, ensure) do
    if active_ui(state) == ensure,
       do: update_in(state.ui.active_stack, &tl/1),
       else: state
  end

end
