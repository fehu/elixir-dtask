defmodule DTask.Task.DTO.Task do
  @moduledoc """
  Represents Task's state from Dispatcher's point of view.
  """

  alias DTask.Task, as: TaskBehaviour
  alias DTask.Task.Dispatcher
  alias DTask.Task.DTO.Free

  # # # # # # # # # # # # # # # # # # # #

  @derive Jason.Encoder
  @enforce_keys [:id, :def, :params]
  defstruct     [:id, :def, :params, :dispatched, :finished]

  @type dispatched :: __MODULE__.Dispatched.t
  @type finished   :: __MODULE__.Finished.t

  @type t :: %__MODULE__{
               id:         Dispatcher.task_id,
               def:        TaskBehaviour.t,
               params:     Free.t(TaskBehaviour.params),
               dispatched: dispatched,
               finished:   finished
             }

  @spec new(non_neg_integer, module, Free.t() | term, dispatched | nil, finished | nil) :: t
  def new(id, task, params, dispatched \\ nil, finished \\ nil)
      when is_integer(id) and id >= 0
       and is_atom(task)
       and (is_struct(dispatched, __MODULE__.Dispatched) or is_nil(dispatched))
       and (is_struct(finished,   __MODULE__.Finished)   or is_nil(finished)),
      do: %__MODULE__{
        id: id,
        def: task,
        params: Free.wrap(params),
        dispatched: dispatched,
        finished: finished
      }


  # # # # # # # # # # # # # # # # # # # #

  defmodule Dispatched do
    @derive Jason.Encoder
    @enforce_keys [:node, :timestamp]
    defstruct     [:node, :timestamp]

    @type t :: %__MODULE__{
                 node: node,
                 timestamp: DateTime.t
               }

    @spec new(node, DateTime.t) :: t
    def new(node, timestamp)
        when is_atom(node)
         and is_struct(timestamp, DateTime),
        do: %__MODULE__{node: node, timestamp: timestamp}
  end

  # # # # # # # # # # # # # # # # # # # #

  defmodule Finished do
    @derive Jason.Encoder
    @enforce_keys [:outcome, :result, :timestamp]
    defstruct     [:outcome, :result, :timestamp]

    @type outcome :: :success | :failure

    @type t :: %__MODULE__{
                 outcome: outcome,
                 result: Free.t(),
                 timestamp: DateTime.t
               }

    @spec new(outcome, Free.t | term, DateTime.t) :: t
    def new(outcome, result, timestamp)
        when outcome in [:success, :failure]
         and is_struct(timestamp, DateTime),
        do: %__MODULE__{
          outcome: outcome,
          result: Free.wrap(result),
          timestamp: timestamp
        }
  end

end
