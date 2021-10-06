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

    defstruct [:tasks, :resource_usage]

    @type tasks :: DTask.Task.Monitor.state | nil
    @type resource_usage :: DTask.ResourceUsage.Collector.usage | nil

    @type t :: %__MODULE__{
                 tasks: tasks,
                 resource_usage: resource_usage
               }
  end

  # # # # # # # # # # # # # # # # # # # #

  defmodule UI do
    use StructAccess

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

end
