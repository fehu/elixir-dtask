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
               react: %{Event.t => (TUI.state -> (state -> state))}
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
  alias ExTermbox.Event
  alias Ratatouille.Constants

  import DTask.Util.Syntax, only: [<|>: 2]

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

  @callback state_key() :: atom
  @callback stateful() :: TUI.Views.Stateful.t

  defmacro __using__(_opts) do
    quote do
      # # # # # Quoted # # # # #
      alias TUI.Views.Stateful.Cursor

      @behaviour Cursor
      @behaviour TUI.Render.Dimensions

      @key_arrow_up    Constants.key(:arrow_up)
      @key_arrow_down  Constants.key(:arrow_down)
      @key_arrow_left  Constants.key(:arrow_left)
      @key_arrow_right Constants.key(:arrow_right)
      @key_page_up     Constants.key(:pgup)
      @key_page_down   Constants.key(:pgdn)
      @key_home        Constants.key(:home)
      @key_end         Constants.key(:end)

      @react %{
        %{key: @key_arrow_up}    => [{:move, [:y, :-]}],
        %{key: @key_arrow_down}  => [{:move, [:y, :+]}],
        %{key: @key_arrow_left}  => [{:move, [:x, :-]}],
        %{key: @key_arrow_right} => [{:move, [:x, :+]}],
        %{key: @key_page_up}     => [{:move, [:y, :--]}],
        %{key: @key_page_down}   => [{:move, [:y, :++]}],
        %{key: @key_home}        => [{:move, [:y, 0]},    {:move, [:x, 0]}],
        %{key: @key_end}         => [{:move, [:y, :max]}, {:move, [:x, 0]}]
      }

      @state_0_key :state

      @spec state_key :: atom
      def state_key, do: :cursor

      @spec stateful() :: TUI.Views.Stateful.t
      def stateful, do: %TUI.Views.Stateful{
        state: %{state_key => %Cursor.State{x: 0, y: 0}},
        react: Stream.map(@react, fn {ev, acts} ->
          {struct(Event, Map.put_new(ev, :type, 1)),
            fn state ->
              fn s0 ->
                update_in s0, [@state_0_key, state_key], fn s ->
                  Stream.map(acts, fn {fk, args} -> apply(__MODULE__, fk, args) end)
                  |> Enum.reduce(s, &(&1.(state, &2)))
                end
              end
            end
          }
        end) |> Enum.into(%{})
      }

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


defmodule DTask.TUI.Views.Stateful.Cursor.MainViewTable do
  use DTask.TUI.Views.Stateful.Cursor

  @spec max_y_view(TUI.state) :: non_neg_integer
  defdelegate max_y_view(state), to: DTask.TUI.Views.MainView, as: :table_rows
end
