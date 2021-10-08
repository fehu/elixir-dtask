defmodule DTask.TUI.Tab do
  @moduledoc false

  alias DTask.TUI
  alias DTask.TUI.Render
  alias DTask.TUI.Views.MainView

  alias ExTermbox.Event
  alias Ratatouille.Constants

  import DTask.Util.Syntax, only: [>>>: 2]

  defmodule Stateful do
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

  defmodule Stateful.Cursor do
    use StructAccess

    defstruct [x: 0, y: 0]

    @state_0_key :state
    @state_key   :cursor

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

    @type t :: %__MODULE__{
                 x: non_neg_integer,
                 y: non_neg_integer
               }

    @type axis :: :x | :y
    @type op   :: :+ | :- | :++ | :-- | :max | 0

    @spec stateful() :: DTask.TUI.Tab.Stateful.t
    def stateful(), do: %DTask.TUI.Tab.Stateful{
      state: %{@state_key => %__MODULE__{x: 0, y: 0}},
      react: Stream.map(@react, fn {ev, acts} ->
        {struct(Event, Map.put_new(ev, :type, 1)),
          fn state ->
            fn s0 ->
              update_in s0, [@state_0_key, @state_key], fn s ->
                Stream.map(acts, fn {fk, args} -> apply(__MODULE__, fk, args) end)
                |> Enum.reduce(s, &(&1.(state, &2)))
              end
            end
          end
        }
      end) |> Enum.into(%{})
    }

    @spec state_key :: atom
    def state_key, do: @state_key

    @spec move(axis, op) :: (TUI.state, t -> t)
    # Operations that require knowing data size
    def move(:y, op) when op in [:+, :++, :max], do: fn state, s ->
      data = state.data[state.ui.tab.data_key]
      max = if data, do: Enum.count(data), else: 0
      page   = fn -> MainView.table_rows(state) end
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
          :-- -> y - MainView.table_rows(state)
        end
        max(new_y, 0)
      end
    end

    # Other operations are not supported
    def move(_, _), do: fn _, s -> s end
  end

  # # # # # # # # # # # # # # # # # # # #
  use StructAccess

  @enforce_keys [:id, :shortcuts, :data_key, :render_main]
  defstruct     [:id, :shortcuts, :data_key, :render_main, :render_side, :stateful]

  @type t :: %__MODULE__{
               id: atom,
               shortcuts: [char],
               data_key: atom,
               render_main: Render.t,
               render_side: Render.t | nil,
               stateful: Stateful.t | [module] | nil
             }

  # # # Build helpers # # #

  require Logger # TODO

  @spec init(t | TUI.State.t) :: t | TUI.State.t
  def init(state) when is_struct(state, TUI.State) do
    update_in(state.ui.tab, &init/1)
  end
  def init(tab) when is_struct(tab, __MODULE__) do
    update_in tab.stateful, fn
      [] ->
        nil
      mods when is_list(mods) ->
        Stream.map(mods, &(&1.stateful)) |> Enum.reduce(&__MODULE__.Stateful.merge/2)
      s when is_struct(s, __MODULE__.Stateful) ->
        s
      _ -> nil
    end
  end

  # # # Access helpers # # #

  @spec cursor(TUI.state, axis) :: non_neg_integer | nil
                                when axis: :x | :y
  def cursor(state, axis) when not is_nil(state.ui.tab.stateful)
                           and not is_nil(state.ui.tab.stateful.state.cursor)
                           and axis in [:x, :y],
      do: state.ui.tab.stateful.state.cursor[axis]
  def cursor(_, _), do: nil
end
