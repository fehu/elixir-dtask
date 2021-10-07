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

    @enforce_keys [:window, :layout, :tab, :table, :show_help]
    defstruct     [:window, :layout, :tab, :table, :show_help]

    @typep pos_int_2 :: {pos_integer, pos_integer}

    @type window :: %{
                      height: non_neg_integer,
                      width: non_neg_integer
                    }

    @type layout :: {:split_horizontal, ratio   :: float}
                  | {:split_vertical,   heights :: pos_int_2}
                  | :table_only

    @type tab :: DTask.TUI.Tab.t

    @type table :: __MODULE__.Table.t

    @type t :: %__MODULE__{
                 window: window,
                 layout: layout,
                 tab: tab,
                 table: table,
                 show_help: boolean
               }

    # # # # # # # # # # # # # # # # # # # #

    defmodule Table do
      use StructAccess

      defstruct [cursor: 0]

      @type t :: %__MODULE__{
                   cursor: non_neg_integer
                 }
    end
  end

end
