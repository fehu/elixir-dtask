defmodule DTask.TUI.Views.Stateful do
  @moduledoc false

  alias DTask.TUI
  alias ExTermbox.Event

  import DTask.Util.Syntax, only: [>>>: 2, <|>: 2, maybe: 2, maybe_2: 3]

  use StructAccess

  @enforce_keys [:state, :react]
  defstruct     [:state, :react]

  @typep state :: %{atom => term}
  @type react_external :: {:open_overlay, TUI.Overlay.t}
                        | :close_overlay

  @type t :: %__MODULE__{
               state: state,
               react: (Event.t, TUI.state -> (state -> state) | [react_external] | nil)
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

  # # # Behaviour utilities # # #

  @type create_spec :: module | {module, (term -> term)}

  @spec create(module, (term -> term) | nil) :: t
  def create(stateful_behaviour, upd \\ nil) when is_atom(stateful_behaviour) do
    stateful = stateful_behaviour.stateful()
    if upd, do: update(stateful, stateful_behaviour, upd), else: stateful
  end

  @spec create_many([create_spec, ...]) :: t | nil
  def create_many([]), do: nil
  def create_many(specs) when is_list(specs),
      do: specs |> Stream.map(fn
                     {mod, fun, args} -> apply(mod, fun, args)
                     {mod, upd}       -> __MODULE__.create(mod, upd)
                     mod              -> __MODULE__.create(mod)
                   end)
                 |> Enum.reduce(&__MODULE__.merge/2)

  @spec update(t, module, (term -> term)) :: t
  def update(stateful_struct, _, nil), do: stateful_struct
  def update(stateful_struct, stateful_behaviour, upd),
      do: update_in(stateful_struct, [:state, stateful_behaviour.state_key], upd)

  # # # Misc utilities # # #

  @spec active_state(TUI.state, atom) :: term | nil
  def active_state(state, key),
      do: maybe(active_stateful(state), &get_in(&1, [:state, key]))

  @spec active_stateful(TUI.state) :: term | nil
  def active_stateful(state),
      do: maybe(TUI.State.active_ui(state), &Map.get(&1, :stateful))

  @spec update_active_stateful(TUI.state, (term -> term)) :: term | nil
  def update_active_stateful(state, upd),
      do: TUI.State.update_active_ui(state, &update_in(&1.stateful, upd))

  @spec find_holder(TUI.state, atom) :: %{required(:stateful) => TUI.Views.Stateful.t} | nil
  def find_holder(state, id),
      do: TUI.Overlay.find(state, id) <|> if(state.ui.tab.id == id, do: state.ui.tab)
end

defmodule DTask.TUI.Views.Stateful.Reactive do
  @state_0_key :state

  alias DTask.TUI
  alias DTask.TUI.Views.Stateful

  import DTask.Util.Syntax, only: [<|>: 2]

  @malformed_or "Malformed :or option: literal fun/2 is expected."

  @doc """
    Bind format: `%{lhs => rhs}` where
    `lhs` define event to match (as map),
    `rhs` define functions to call (name and args)

    Example
    ```
     bind: %{
            %{key: Keys.arrow_up} => [{:func_name, [arg1, arg2, ...]}],
            %{key: Keys.ctrl_s}   => {:external, [{:func_name, [arg1, arg2, ...]}]},
           }
    ```

    Required:
      * `bind`
    Options:
      * `init: state`
      * `or: fn event, state -> (s -> s) | nil end`
  """
  defmacro __using__(opts) do
    init_state = opts[:init]
    binds = case opts[:bind] do
      {:%{}, _, binds} -> binds
      nil              -> raise "Undefined `:bind`"
      _                -> raise "Malformed `:bind`"
    end
    [v_s, v_state, v_tmp] = Macro.generate_arguments(3, __CALLER__.module)
    module  = quote do: __MODULE__
    clauses = Enum.flat_map binds, fn
      {{:%{}, _, lhs}, {:external, rhs_0}} ->
        rhs = Enum.map rhs_0, fn
          {f, args} ->
            quote do
              # >> __MODULE__.f(..args..).(TUI.state) <<
              # f return type is expected to be (TUI.state -> react_external | [react_external])
              case unquote(module).unquote(f)(unquote_splicing(args)).(unquote(v_state)) do
                unquote(v_tmp) when is_list(unquote(v_tmp)) -> unquote(v_tmp)
                unquote(v_tmp)                              -> [unquote(v_tmp)]
              end
            end
        end
        quote do: (%{unquote_splicing(lhs)}, unquote(v_state) -> Enum.concat(unquote(rhs)))
      {{:%{}, _, lhs}, rhs_0} ->
        apply_rhs = Enum.reduce rhs_0, v_s, fn
          {f, args}, s ->
            quote do
              # >> __MODULE__.f(..args..).(TUI.state, state) <<
              # f return type is expected to be (TUI.state, state -> state)
              unquote(module).unquote(f)(unquote_splicing(args)).(unquote(v_state), unquote(s))
            end
        end
        rhs = update_state_expr v_s, quote do: fn unquote(v_s) -> unquote(apply_rhs) end
        quote do: (%{unquote_splicing(lhs)}, unquote(v_state) -> unquote(rhs))
    end

    or_clauses = case opts[:or] do
      {:fn, _, cs} ->
        Enum.map cs, fn
          {:->, m0, [lhs=[{_event, _, _}, {_state_v, _, _}], rhs]} ->
            {:->, m0, [lhs, update_state_expr(v_s, rhs)]}
          {:->, m0, [lhs=[{:when, _, [{_event, _, _}, {_state_v, _, _}, _]}], rhs]} ->
            {:->, m0, [lhs, update_state_expr(v_s, rhs)]}
          _ ->
            raise @malformed_or
        end
      nil -> []
      _   -> raise @malformed_or
    end

    default_clauses = quote do: (_, _ -> nil)

    react = {:fn, [], clauses ++ or_clauses ++ default_clauses}

    quote do
      @behaviour Stateful

      @impl true
      @spec stateful() :: Stateful.t
      def stateful, do: %Stateful{
        state: %{state_key() => unquote(init_state)},
        react: unquote(react)
      }
    end
  end

  defp update_state_expr(v_state, f_expr) do
    quote do
      fn unquote(v_state) ->
        update_in unquote(v_state),
                  [unquote(@state_0_key), __MODULE__.state_key],
                  unquote(f_expr)
      end
    end
  end

end

defmodule DTask.TUI.Views.Stateful.Cursor do
  alias DTask.TUI

  import DTask.Util.Syntax, only: [<|>: 2, maybe: 2]

  @type state :: %{
                   required(:x) => non_neg_integer,
                   required(:y) => non_neg_integer
                 }

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

  @callback max_x(TUI.state, state) :: non_neg_integer
  @callback max_y(TUI.state, state) :: non_neg_integer

  @callback inner_height(TUI.state, state) :: non_neg_integer
  @callback inner_width(TUI.state, state) :: non_neg_integer

  @optional_callbacks max_x: 2, max_y: 2, inner_height: 2, inner_width: 2

  @doc """
  Requires optional callbacks `max_y: 1` and `inner_height: 1`.
  """
  defmacro __using__(opts) do
    quote do
      # # # # # Quoted # # # # #
      alias TUI.Views.Stateful
      alias TUI.Views.Stateful.Cursor

      @behaviour Cursor

      use DTask.TUI.Util.Keys
      use TUI.Views.Stateful.Reactive,
          init: %{
            x: 0,
            y: 0,
            max_y: unquote(opts[:max_y]),
            inner_height: unquote(opts[:inner_height])
          },
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

      @impl true
      @spec state_key :: atom
      def state_key, do: :cursor

      @impl true
      @spec move(Cursor.axis, Cursor.op) :: (TUI.state, Cursor.state -> Cursor.state)
      # Operations that require knowing data size
      def move(:y, op) when op in [:+, :++, :max], do: fn state, s ->
        max = __MODULE__.max_y(state, s)
        page = fn -> __MODULE__.inner_height(state, s) end
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
            :-- -> y - __MODULE__.inner_height(state, s)
          end
          max(new_y, 0)
        end
      end

      # Other operations are not supported yet
      def move(_, _), do: fn _, s -> s end

      @spec max_y(TUI.state, Cursor.state) :: non_neg_integer
      def max_y(state, s), do: maybe(s.max_y, s.max_y.(state)) <|> 0

      @spec inner_height(TUI.state, Cursor.state) :: non_neg_integer
      def inner_height(state, s), do: maybe(s.inner_height, s.inner_height.(state)) <|> 0

      defoverridable move: 2, state_key: 0, max_y: 2, inner_height: 2
      # # # # # End Quoted # # # # #
    end
  end

end

defmodule DTask.TUI.Views.Stateful.OneLineInput do

  import DTask.Util.Syntax, only: [<|>: 2]

  # # # # # # # # # # # # # # # # # # # #

  defmodule State do
    use StructAccess

    defstruct [cursor: 0, offset: 0, text: []]

    @type t :: %__MODULE__{
                 cursor: non_neg_integer,
                 offset: non_neg_integer | nil,
                 text: charlist
               }
  end

  @type state :: __MODULE__.State.t

  # # # # # # # # # # # # # # # # # # # #

  @type move_op :: {:+, pos_integer | [char, ...]}
                 | {:-, pos_integer | [char, ...]}
                 | :++
                 | :--
                 | :first
                 | :last
  @callback move(move_op) :: (TUI.state, state -> state)
  @callback print(char) :: (TUI.state, state -> state)
  @callback delete(:+ | :-, integer | [char, ...]) :: (TUI.state, state -> state)

  @callback set_text(state, TUI.state, charlist | String.t, cursor: 0 | :last) :: state

  @callback input_width(TUI.state) :: non_neg_integer
  @optional_callbacks input_width: 1

  # # # # # # # # # # # # # # # # # # # #

  @default_long_sep  [?\s]
  @default_short_sep [?\s]

  @doc """
  Supported ops:
    * `long_sep: [char]`
      Controls `ctrl_arrow_right`, `ctrl_arrow_left`, `ctrl_w`.
    * `short_sep: [char]`
      Controls `arrow_up`, `arrow_down`, `ctrl_backspace`, `ctrl_delete_ch`.
    * Overrides
      * `init: state`
      * `bind: {:replace | :add, binds}`
      * `or: fn %event, TUI.state -> (state -> state) end`
  """
  defmacro __using__(opts) do
    long_sep  = opts[:long_sep]  <|> @default_long_sep
    short_sep = opts[:short_sep] <|> @default_short_sep

    default_init = quote do: %unquote(__MODULE__).State{}
    default_bind = quote do
      %{
        # Navigate
        %{key: @arrow_right}          => [{:move, [+: 1]}],
        %{key: @arrow_left}           => [{:move, [-: 1]}],
        %{key: @arrow_up}             => [{:move, [+: unquote(short_sep)]}],
        %{key: @arrow_down}           => [{:move, [-: unquote(short_sep)]}],
        %{esc: @ctrl_arrow_right_esc} => [{:move, [+: unquote(long_sep)]}],
        %{esc: @ctrl_arrow_left_esc}  => [{:move, [-: unquote(long_sep)]}],
        %{esc: @ctrl_arrow_up_esc}    => [{:move, [:first]}],
        %{esc: @ctrl_arrow_down_esc}  => [{:move, [:last]}],
        %{key: @home}                 => [{:move, [:first]}],
        %{key: @end_}                 => [{:move, [:last]}],
        %{key: @page_up}              => [{:move, [:--]}],
        %{key: @page_down}            => [{:move, [:++]}],
        # Delete
        %{key: @delete}          => [{:delete, [:+, 1]}],
        %{key: @backspace}       => [{:delete, [:-, 1]}],
        %{key: @ctrl_backspace}  => [{:delete, [:-, unquote(short_sep)]}],
        %{key: @ctrl_w}          => [{:delete, [:-, unquote(long_sep)]}],
        %{esc: @ctrl_delete_esc} => [{:delete, [:+, unquote(short_sep)]}],
        # Input
        %{key: @space} => [{:print, [?\s]}]
      }
    end
    default_or = quote do
      fn
        %{ch: ch}, s when ch != 0 -> &(__MODULE__.print(ch).(s, &1))
      end
    end

    quote do
      # # # # # Quoted # # # # #
      alias DTask.TUI.Views.Stateful.OneLineInput

      @behaviour OneLineInput

      use DTask.TUI.Util.Escaped
      use DTask.TUI.Util.Keys
      use DTask.TUI.Views.Stateful.Reactive,
          init: unquote(opts[:init] <|> default_init),
          bind: unquote(opts[:bind] <|> default_bind),
          or:   unquote(opts[:or]   <|> default_or)

      @impl true
      @spec state_key :: atom
      def state_key, do: :text_input

      @impl true
      @spec move(OneLineInput.move_op) :: (TUI.state, OneLineInput.state -> OneLineInput.state)
      def move({:+, n})   when is_integer(n), do: upd_cursor(&(&1.cursor + n))
      def move({:-, n})   when is_integer(n), do: upd_cursor(&(&1.cursor - n))
      def move({:+, sep}) when is_list(sep),  do: upd_cursor(&(next_index_of(&1, sep) <|> max_cursor(&1)))
      def move({:-, sep}) when is_list(sep),  do: upd_cursor(&(next_index_of(&1, sep, :rev) <|> 0))
      def move(:++),    do: upd_cursor(&(&2.cursor + round(input_width(&1) / 2)))
      def move(:--),    do: upd_cursor(&(&2.cursor - round(input_width(&1) / 2)))
      def move(:first), do: upd_cursor(fn _ -> 0 end, :unsafe)
      def move(:last),  do: upd_cursor(fn _, s -> max_cursor(s) end, :unsafe)
      # Other operations are not supported
      def move(_), do: fn _, s -> s end


      @impl true
      @spec print(char) :: (TUI.state, OneLineInput.state -> OneLineInput.state)
      def print(ch), do: fn state, s ->
        update_in(s.text, &List.insert_at(&1, s.cursor, ch))
        |> upd_cursor_0(s.cursor + 1, state, :unsafe)
      end


      @impl true
      @spec delete(:+ | :-, integer | [char, ...]) :: (TUI.state, OneLineInput.state -> OneLineInput.state)
      def delete(op, arg), do: fn state, s ->
        {erase_l, erase_r} = case {op, arg} do
          {:+, i} when is_integer(i) -> {nil, s.cursor + i}
          {:+, l} when is_list(l)    -> {nil, next_index_of(s, l, :rev) <|> max_cursor(s)}
          {:-, i} when is_integer(i) -> {max(0, s.cursor - i), nil}
          {:-, l} when is_list(l)    -> {next_index_of(s, l, :rev) <|> 0, nil}
        end
        erase_start = erase_l <|> s.cursor
        erase_end   = erase_r <|> s.cursor
        erase_len   = erase_end - erase_start
        {lhs, rhs}  = Enum.split(s.text, erase_start)
        new_text    = lhs ++ Enum.drop(rhs, erase_len)

        new_s_0 = put_in(s.text, new_text)
        if erase_l, do: upd_cursor_0(new_s_0, erase_l, state),
                  else: upd_offset(new_s_0, s.cursor, state)
      end

      @impl true
      @spec set_text(
              OneLineInput.state,
              TUI.state,
              charlist | String.t,
              cursor: 0 | :last
            ) :: OneLineInput.state
      def set_text(s, state, text_0, cursor: c) do
        text = if is_list(text_0), do: text_0, else: String.to_charlist(text_0)
        cur = case c do
          0     -> 0
          :last -> length(text)
        end
        upd_cursor_0(%{s | :text => text}, cur, state, :unsafe)
      end

      defp next_index_of(s, sep, rev \\ nil) do
        cur = s.cursor
        i = if rev, do: Enum.take(s.text, cur - 1)
                     |> Enum.reverse
                     |> Enum.find_index(&(&1 in sep)),
                  else: Enum.drop(s.text, cur + 1)
                     |> Enum.find_index(&(&1 in sep))
        unless is_nil(i),
               do: if(rev, do: cur - i - 1, else: cur + i + 1),
               else: nil
      end

      defp upd_cursor(f, unsafe \\ nil)
      defp upd_cursor(f, unsafe) when is_function(f, 1),
           do: upd_cursor(fn _, c -> f.(c) end, unsafe)
      defp upd_cursor(f, unsafe) when is_function(f, 2),
           do: &upd_cursor_0(&2, f.(&1, &2), &1, unsafe)

      defp upd_cursor_0(s, cur, state, unsafe \\ nil) do
        new_cur = unless unsafe,
                         do: safe_cursor(cur, s),
                         else: cur

        s |> put_in([:cursor], new_cur) |> upd_offset(new_cur, state)
      end

      defp upd_offset(s, cur, state) do
        max_v = input_width(state)
        out_of_view = cur <= s.offset
        or cur >= max_v
        if out_of_view do
          # Center view of cursor
          max_offset = max_cursor(s) - max_v
          new_offset = case cur - round(max_v / 2) do
            offset when offset < 0          -> 0
            offset when offset > max_offset -> max_offset
            offset                          -> offset
          end
          %{s | :offset => new_offset}
        else
          s
        end
      end

      defp safe_cursor(cur, _) when cur <= 0, do: 0
      defp safe_cursor(cur, s) do
        max = max_cursor(s)
        if cur > max, do: max, else: cur
      end

      defp max_cursor(s), do: length(s.text)

      defoverridable delete: 2, move: 1, print: 1, state_key: 0
      # # # # # End Quoted # # # # #
    end
  end

end
