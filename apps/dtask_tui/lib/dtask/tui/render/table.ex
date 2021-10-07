defmodule DTask.TUI.Render.Table do
  @moduledoc false

  alias DTask.TUI

  @typep cached :: term
  @typep n_rows :: pos_integer
  @typep row :: term
  @typep index :: non_neg_integer
  @typep selected? :: boolean

  @callback table_title :: String.t
  @callback data_key :: atom
  @callback pre_render(TUI.state) :: cached
  @callback slice_data(TUI.state, n_rows, cached) :: [{row, index}]
  @callback render_header(TUI.state, cached) :: Element.t
  @callback prepare_data(any) :: row
  @callback render_row(row, cached, selected?) :: Element.t

  defmacro __using__(_) do
    quote do
      alias Ratatouille.Constants
      import Ratatouille.View

      @behaviour TUI.Render
      @behaviour TUI.Render.Table

      @const_table_height 5

      @impl TUI.Render
      @spec render(TUI.state) :: Element.t
      def render(state) do
        free_height = main_height(state)
        {panel_height, n_rows} = case state.ui.layout do
          {:split_horizontal, ratio} ->
            h = max(round(free_height * ratio), 1)
            {h + @const_table_height, h}
          _ ->
            {:fill, free_height - @const_table_height}
        end
        cached = pre_render(state)
        panel(title: table_title(), height: panel_height) do
          table do
            render_header(state, cached)
            for {row, index} <- slice_data(state, n_rows, cached) do
              render_row(row, cached, index == state.ui.table.cursor)
            end
          end
        end
      end

      @impl TUI.Render.Table
      @spec pre_render(TUI.state) :: term
      def pre_render(state), do: nil

      @impl TUI.Render.Table
      def prepare_data(data), do: Enum.sort_by(data, &elem(&1, 0))

      @impl TUI.Render.Table
      @spec slice_data(TUI.state, pos_integer, term) :: [term]
      def slice_data(state, n_rows, _cache) do
        case state.data[data_key()] do
          nil -> []
          data_0 ->
            data = prepare_data(data_0)
            n_data = Enum.count(data)
            half_rows = round(n_rows / 2)
            offset = case state.ui.table.cursor do
              n when n < half_rows          -> 0
              n when n > n_data - half_rows -> n_data - n_rows
              n                             -> n - half_rows
            end

            data |> Stream.with_index |> Enum.slice(offset, n_rows)
        end
      end

      defp main_height(state) do
        state.ui.window.height - state.ui.const_height_f.(state)
      end

      defoverridable pre_render: 1, slice_data: 3, prepare_data: 1
    end
  end

end
