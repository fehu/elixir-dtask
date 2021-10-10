defmodule DTask.TUI.Views.Stateful do
  @moduledoc false

  alias ExTermbox.Event

  import DTask.Util.Syntax, only: [>>>: 2]

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
      react: Map.merge(x.react, y.react, fn _, fx, fy ->
        fn state -> fx.(state) >>> fy.(state) end
      end)
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
  defmacro __using__(init: state, bind: react) do
    [e, s1, s0, s, rhs] = Macro.generate_arguments(5, __MODULE__)
    quote do
      @behaviour Stateful

      @spec stateful() :: Stateful.t
      def stateful, do: %Stateful{
        state: %{state_key() => unquote(state)},
        react: fn unquote(e), unquote(s1) ->
          unquote(rhs) = if unquote(e).ch != 0,
                            do: unquote(react)[%{ch: unquote(e).ch}],
                            else: unquote(react)[%{key: unquote(e).key}]
          if unquote(rhs) do
            fn unquote(s0) ->
              update_in unquote(s0), [unquote(@state_0_key), __MODULE__.state_key], fn unquote(s) ->
                unquote(rhs)
                |> Stream.map(&apply(__MODULE__, elem(&1, 0), elem(&1, 1)))
                |> Enum.reduce(unquote(s), &(&1.(unquote(s1), &2)))
              end
            end
          end
        end
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

  @behaviour TUI.Views.Stateful
  @callback state_key :: atom
  @callback stateful :: TUI.Views.Stateful.t

  @behaviour TUI.Render.Dimensions
  @callback max_x_view(TUI.state) :: non_neg_integer
  @callback max_y_view(TUI.state) :: non_neg_integer

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
        data = state.data[state.ui.tab.data_key]
        max = if data, do: Enum.count(data), else: 0
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
