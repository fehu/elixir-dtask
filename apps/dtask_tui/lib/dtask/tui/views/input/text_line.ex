defmodule DTask.TUI.Views.Input.TextLine do
  @moduledoc false

  alias DTask.TUI
  alias DTask.TUI.Views.Stateful
  alias Ratatouille.Constants

  import DTask.Util.Syntax, only: [<|>: 2]
  import Ratatouille.View

  @callback state_key :: atom
  @callback input_width(TUI.State.t) :: non_neg_integer

  @callback input_style(TUI.State.t) :: String.t
  @callback cursor_style(TUI.State.t) :: String.t
  @callback fill_style(TUI.State.t) :: String.t


  @white Constants.color(:white)
  @black Constants.color(:black)
  @underline Constants.attribute(:underline)

  @default_input_style  [background: @white, color: @black, attributes: [@underline]]
  @default_cursor_style [background: @black, color: @white]
  @default_fill_style   @default_input_style

  defmacro __using__(_opts) do
    quote do
      # # # # # Quoted # # # # #
      @behaviour TUI.Render
      @behaviour TUI.Views.Input.TextLine

      import Ratatouille.View

      @impl TUI.Render
      @spec render(TUI.state) :: Element.t
      def render(state) do
        input_s = Stateful.active_state(state, state_key())
        width   = __MODULE__.input_width(state)
        visible = Enum.slice(input_s.text, input_s.offset, width)
        cur_idx = input_s.cursor - input_s.offset
        fill    = width - length(visible) + 1

        text = case Enum.split(visible, cur_idx) do
          {lhs, [c | rhs]} -> render_input(state, lhs, c,    rhs, fill)
          {lhs, []}        -> render_input(state, lhs, [?\s], [],  fill - 1)
        end

        label([], text)
      end

      defp render_input(state, lhs, c, rhs, fill) do
        input_style  = __MODULE__.input_style(state)
        cursor_style = __MODULE__.cursor_style(state)
        fill_style   = __MODULE__.fill_style(state)

        [
          text([{:content, to_string(lhs)} | input_style]),
          text([{:content, to_string([c])} | cursor_style]),
          text([{:content, to_string(rhs)} | input_style])
        ] ++ if fill > 0,
                do: [text([{:content, String.duplicate(" ", fill)} | fill_style])],
                else: []
      end

      @impl TUI.Views.Input.TextLine
      def input_style(_), do: unquote(@default_input_style)

      @impl TUI.Views.Input.TextLine
      def cursor_style(_), do: unquote(@default_cursor_style)

      @impl TUI.Views.Input.TextLine
      def fill_style(_), do: unquote(@default_fill_style)

      defoverridable input_style: 1, cursor_style: 1, fill_style: 1
      # # # # # End Quoted # # # # #
    end
  end

  defmodule Path do
    def long_sep, do:  [?/, ?\\]
    def short_sep, do: [?\s, ?., ?_, ?-, ?:]
  end

end
