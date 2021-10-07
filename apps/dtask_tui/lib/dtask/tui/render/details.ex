defmodule DTask.TUI.Render.Details do
  @moduledoc false

  alias DTask.TUI
  alias Ratatouille.Renderer.Element

  @callback render_details(TUI.state, term) :: Element.t
  @callback render_empty(TUI.state) :: Element.t

  defmacro __using__(_) do
    quote do
      # # # # # Quoted # # # # #
      alias Ratatouille.Constants
      import Ratatouille.View

      @behaviour TUI.Render
      @behaviour TUI.Render.Details

      @impl TUI.Render
      @spec render(TUI.state) :: Element.t
      def render(state) do
        data = state.data[state.ui.tab.data_key]
        selected = if data, do: Enum.at(data, state.ui.table.cursor)

        if selected, do: render_details(state, selected), else: render_empty(state)
      end

      @impl TUI.Render.Details
      @spec render_empty(TUI.state) :: Element.t
      def render_empty(_) do
        panel height: :fill, background: Constants.color(:white)
      end

      @spec render_inspect(term) :: Element.t
      def render_inspect(x) do
        panel title: "Inspect", height: :fill do
          label(content: inspect(x, pretty: true, width: 0))
        end
      end

      defoverridable render_empty: 1
      # # # # # End Quoted # # # # #
    end
  end

end
