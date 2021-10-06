defmodule DTask.TUI.Render.Table do
  @moduledoc false

  alias DTask.TUI

  @typep cached :: term
  @typep row :: term
  @typep index :: non_neg_integer
  @typep selected? :: boolean

  @callback table_title :: String.t
  @callback data_key :: atom
  @callback pre_render(TUI.state) :: cached
  @callback slice_data(TUI.state, cached) :: [{row, index}]
  @callback render_header(TUI.state, cached) :: Element.t
  @callback render_row(row, cached, selected?) :: Element.t

  defmacro __using__(_) do
    quote do
      @behaviour TUI.Render
      @behaviour TUI.Render.Table

      @impl TUI.Render
      @spec render(TUI.state) :: Element.t
      def render(state) do
        panel_height = case state.ui.layout do
          {:split_horizontal, {h, _}} -> h
          _                           -> :fill
        end
        cached = pre_render(state)
        panel(title: table_title(), height: panel_height) do
          table do
            render_header(state, cached)
            for {row, index} <- slice_data(state, cached) do
              render_row(row, cached, index == state.ui.table.cursor)
            end
          end
        end
      end

      @impl TUI.Render.Table
      @spec pre_render(TUI.state) :: term
      def pre_render(state), do: nil

      @impl TUI.Render.Table
      @const_table_height 5
      @spec slice_data(TUI.state, term) :: [term]
      def slice_data(state, _cache) do
        case state.data[data_key()] do
          nil -> []
          data ->
            n_data = case data do
              nil -> 0
              _   -> Enum.count(data)
            end

            table_height = state.ui.window.height - state.ui.const_height_f.(state)
            n_rows = table_height - @const_table_height
            half_rows = round(n_rows / 2)
            offset = case state.ui.table.cursor do
              n when n < half_rows          -> 0
              n when n > n_data - half_rows -> n_data - n_rows
              n                             -> n - half_rows
            end

            data |> Stream.with_index |> Enum.slice(offset, n_rows)
        end
      end

      defoverridable pre_render: 1, slice_data: 2
    end
  end

end
