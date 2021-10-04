defmodule DTask.TUI.State do
  @moduledoc false

  defmodule Connection do
    @enforce_keys [:this_node, :this_node_up, :ctrl_node, :connected]
    defstruct     [:this_node, :this_node_up, :ctrl_node, :connected]

    @type t :: %__MODULE__{
                 this_node: node,
                 this_node_up: boolean,
                 ctrl_node: node,
                 connected: boolean
               }
  end

  defmodule Data do
    defstruct [:tasks, :resource_usage]

    @type t :: %__MODULE__{
                 tasks: DTask.Task.Monitor.state,
                 resource_usage: DTask.ResourceUsage.Collector.usage
               }
  end

  defmodule UI do
    @enforce_keys [:window, :layout, :active_tab, :show_tabs, :show_help]
    defstruct     [:window, :layout, :active_tab, :show_tabs, :show_help]

    @typep pos_int_2 :: {pos_integer, pos_integer}

    @type window :: %{
                      height: non_neg_integer,
                      width: non_neg_integer
                    }

    @type layout :: {:horizontal, heights :: pos_int_2}
                  | {:vertical,   ratio :: pos_int_2}
                  | :table_only

    @type tab :: :executors
               | :tasks_all
               | :tasks_finished
               | :tasks_pending
               | :tasks_running

    @type t :: %__MODULE__{
                 window: window,
                 layout: layout,
                 active_tab: tab,
                 show_tabs: boolean,
                 show_help: boolean
               }
  end

  # # # # # # # # # # # # # # # # # # # #

  @enforce_keys [:connection, :data, :ui]
  defstruct     [:connection, :data, :ui]

  @type connection :: Connection.t
  @type data       :: Data.t
  @type ui         :: UI.t

  @type t :: %__MODULE__{
               connection: connection,
               data: data,
               ui: ui
             }
  # # # # # # # # # # # # # # # # # # # #
end