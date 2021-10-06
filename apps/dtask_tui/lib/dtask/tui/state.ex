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

    defstruct [:test, :tasks, :resource_usage]

    @type tasks :: DTask.Task.Monitor.state | nil
    @type resource_usage :: DTask.ResourceUsage.Collector.usage | nil

    @type t :: %__MODULE__{
                 tasks: tasks,
                 resource_usage: resource_usage,
                 test: [integer]
               }
  end

  # # # # # # # # # # # # # # # # # # # #

  defmodule UI do
    use StructAccess

    @enforce_keys [:window, :layout, :const_height_f, :tab, :table, :show_help]
    defstruct     [:window, :layout, :const_height_f, :tab, :table, :show_help]

    @typep pos_int_2 :: {pos_integer, pos_integer}

    @type window :: %{
                      height: non_neg_integer,
                      width: non_neg_integer
                    }

    @type layout :: {:split_horizontal, heights :: pos_int_2}
                  | {:split_vertical,   ratio :: pos_int_2}
                  | :table_only

    @type tab :: :executors
               | :tasks_all
               | :tasks_finished
               | :tasks_pending
               | :tasks_running
               | :test

    @type table :: __MODULE__.Table.t

    @type t :: %__MODULE__{
                 window: window,
                 layout: layout,
                 const_height_f: (DTask.TUI.state -> non_neg_integer),
                 tab: tab,
                 table: table,
                 show_help: boolean
               }

    # # # # # # # # # # # # # # # # # # # #

    defmodule Table do
      use StructAccess

      @enforce_keys [:data_key]
      defstruct     [:data_key, cursor: 0]

      @type t :: %__MODULE__{
                   data_key: atom,
                   cursor: non_neg_integer
                 }
    end
  end

end
