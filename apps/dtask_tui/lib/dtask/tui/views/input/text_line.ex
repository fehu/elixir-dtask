defmodule DTask.TUI.Views.Input.TextLine do
  @moduledoc false

  alias DTask.TUI
  alias Ratatouille.Constants

  import DTask.Util.Syntax, only: [<|>: 2]
  import Ratatouille.View

  @input_attrs     [Constants.attribute(:underline)]
  @input_background Constants.color(:white)
  @input_color      Constants.color(:black)
  @input_style [background: @input_background, color: @input_color, attributes: @input_attrs]

  @cursor_attrs      []
  @cursor_background Constants.color(:black)
  @cursor_color      Constants.color(:white)
  @cursor_style [background: @cursor_background, color: @cursor_color, attributes: @cursor_attrs]

  @fill_style @input_style

  @type cfg :: %{
                 required(:input_width) => (TUI.state -> non_neg_integer),
                 optional(:title)       => String.t
               }
  @spec make(cfg) :: (TUI.state -> Element.t())
  def make(cfg) when is_map_key(cfg, :input_width), do: fn state ->
    input_s = state.ui.overlay.stateful.state.text_input
    width   = cfg.input_width.(state)
    visible = Enum.slice(input_s.text, input_s.offset, width)
    cur_idx = input_s.cursor - input_s.offset
    fill = width - length(visible) + 1

    text = case Enum.split(visible, cur_idx) do
      {lhs, [c | rhs]} -> render_input(lhs, c,    rhs, fill)
      {lhs, []}        -> render_input(lhs, [? ], [],  fill - 1)
    end

    panel(title: cfg[:title]) do
      label([], text)
    end
  end

  defp render_input(lhs, c, rhs, fill) do
    [
      text([{:content, to_string(lhs)} | @input_style]),
      text([{:content, to_string([c])} | @cursor_style]),
      text([{:content, to_string(rhs)} | @input_style])
    ] ++ if fill > 0,
            do: [text([{:content, String.duplicate(" ", fill)} | @fill_style])],
            else: []
  end

  defmodule Path do
    @moduledoc """
    `Stateful` implementation.
    """

    alias DTask.TUI.Views.Stateful
    # Implements
    # @behaviour Stateful
    # @behaviour Stateful.OneLineInput

    @long_sep  [?/, ?\\]
    @short_sep [? , ?., ?_, ?-, ?:]

    use Stateful.OneLineInput,
        long_sep:  @long_sep,
        short_sep: @long_sep ++ @short_sep

    # TODO ==============================
    @impl true
    @spec input_width(TUI.state) :: non_neg_integer
    def input_width(_), do: 20

#        do: get_in(state, TUI.State.active_ui_keys(state) ++ [:stateful, state_key(), :cfg, :input_width])
#        <|> TUI.Overlay.width(state)
  end
end
