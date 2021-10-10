defmodule DTask.TUI.Views.Stateful do
  @moduledoc false

  alias ExTermbox.Event

  import DTask.Util.Syntax, only: [>>>: 2, maybe_2: 3]

  use StructAccess

  @enforce_keys [:state, :react]
  defstruct     [:state, :react]

  @typep state :: map()

  @type t :: %__MODULE__{
               state: state,
               react: (Event.t, TUI.state -> (state -> state) | nil)
             }

  @spec merge(t, t) :: t
  def merge(x, y) when is_struct(x, __MODULE__)
                   and is_struct(y, __MODULE__) do
    %__MODULE__{
      state: Map.merge(x.state, y.state),
      react: fn ev, state ->
        maybe_2(x.react.(ev, state), y.react.(ev, state), &>>>/2)
      end
    }
  end

  # # # Behaviour # # #

  @callback state_key :: atom
  @callback stateful() :: t
end

defmodule DTask.TUI.Views.Stateful.Reactive do
  @state_0_key :state

  alias DTask.TUI.Views.Stateful
  alias ExTermbox.Event

  @doc """
    Bind format: `%{lhs => rhs}` where
    `lhs` define event to match (key/value pairs),
    `rhs` define functions to call (name and args)
  """
  defmacro __using__(init: state, bind: {:%{}, _, binds}) do
    [ev, s0, s1, s2] = Macro.generate_arguments(4, __MODULE__)
    module  = quote do: __MODULE__
    clauses = Enum.flat_map binds, fn {{:%{}, _, lhs}, rhs_0} ->
      apply_rhs = Enum.reduce rhs_0, s0, fn
        {f, args}, s ->
          quote do
            # >> __MODULE__.f(..args..).(TUI.state, state) <<
            # f return type is expected to be (TUI.state, state -> state)
            unquote(module).unquote(f)(unquote_splicing(args)).(unquote(s2), unquote(s))
          end
      end

      rhs = quote do
        fn unquote(s1) ->
          update_in unquote(s1),
                    [unquote(@state_0_key), __MODULE__.state_key],
                    fn unquote(s0) -> unquote(apply_rhs) end
        end
      end

      quote do: (%Event{unquote_splicing(lhs)}, unquote(s2) -> unquote(rhs))
    end

    default_clauses = quote do: (_, _ -> nil)

    react = {:fn, [], clauses ++ default_clauses}

    quote do
      @behaviour Stateful

      @spec stateful() :: Stateful.t
      def stateful, do: %Stateful{
        state: %{state_key() => unquote(state)},
        react: unquote(react)
      }
    end
  end
end

defmodule DTask.TUI.Views.Stateful.Cursor do
  defmodule State do
    use StructAccess

    defstruct [x: 0, y: 0]

    @type t :: %__MODULE__{
                 x: non_neg_integer,
                 y: non_neg_integer
               }
  end

  alias DTask.TUI

  @type state :: __MODULE__.State.t

  @typep axis :: :x | :y
  @typep op   :: :+
               | :-
               | :max
               | non_neg_integer
               | :++
               | {:++, integer}
               | {:++, float, :total | :view}
               | :--
               | {:--, integer}
               | {:--, float, :total | :view}

  @callback move(axis, op) :: (TUI.state, state -> state)

  # Optional callbacks

  @callback max_x(TUI.state) :: non_neg_integer
  @callback max_y(TUI.state) :: non_neg_integer

  @callback max_x_view(TUI.state) :: non_neg_integer
  @callback max_y_view(TUI.state) :: non_neg_integer

  @optional_callbacks max_x: 1, max_y: 1, max_x_view: 1, max_y_view: 1

  @doc """
  Requires optional callbacks `max_y: 1` and `max_y_view: 1`.
  """
  defmacro __using__(_opts) do
    quote do
      # # # # # Quoted # # # # #
      alias TUI.Views.Stateful.Cursor

      @behaviour Cursor

      use DTask.TUI.Util.Keys
      use TUI.Views.Stateful.Reactive,
          init: %Cursor.State{x: 0, y: 0},
          bind: %{
            %{key: @arrow_up}    => [{:move, [:y, :-]}],
            %{key: @arrow_down}  => [{:move, [:y, :+]}],
            %{key: @arrow_left}  => [{:move, [:x, :-]}],
            %{key: @arrow_right} => [{:move, [:x, :+]}],
            %{key: @page_up}     => [{:move, [:y, :--]}],
            %{key: @page_down}   => [{:move, [:y, :++]}],
            %{key: @home}        => [{:move, [:y, 0]},    {:move, [:x, 0]}],
            %{key: @end_}        => [{:move, [:y, :max]}, {:move, [:x, 0]}]
          }

      @spec state_key :: atom
      def state_key, do: :cursor

      @spec move(Cursor.axis, Cursor.op) :: (TUI.state, Cursor.state -> Cursor.state)
      # Operations that require knowing data size
      def move(:y, op) when op in [:+, :++, :max], do: fn state, s ->
        max = max_y(state)
        page = fn -> __MODULE__.max_y_view(state) end
        {cond, upd_s} = case op do
          :+   -> {s.y < max - 1, fn -> update_in(s.y, &(&1 + 1)) end}
          :++  -> {true,          fn -> update_in(s.y, &min(&1 + page.(), max - 1)) end}
          :max -> {true,          fn -> put_in(s.y, max - 1) end}
          i    -> {i <= max,      fn -> put_in(s.y, i) end}
        end
        if cond, do: upd_s.(), else: s
      end
      def move(:y, 0), do: fn _, s -> put_in(s.y, 0) end
      def move(:y, op) when op in [:-, :--], do: fn state, s ->
        update_in s.y, fn y ->
          new_y = case op do
            :-  -> y - 1
            :-- -> y - max_y_view(state)
          end
          max(new_y, 0)
        end
      end

      # Other operations are not supported yet
      def move(_, _), do: fn _, s -> s end

      defoverridable move: 2, state_key: 0
      # # # # # End Quoted # # # # #
    end
  end

end
