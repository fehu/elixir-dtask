defmodule DTask.TUI.Views.TestTable do
  @moduledoc false

  alias Ratatouille.Constants
  import Ratatouille.View

  use DTask.TUI.Render.Table

  @table_title "Test"

  @data_key :test

  @row_style []
  @row_selected_style [
    color: Constants.color(:black),
    background: Constants.color(:white)
  ]

  @impl true
  @spec data_key :: atom
  def data_key, do: @data_key

  @impl true
  @spec table_title :: String.t
  def table_title, do: @table_title

  @impl true
  @spec render_header(TUI.state, any) :: Element.t
  def render_header(_, _) do
    table_row do
      table_cell(content: "X")
    end
  end

  @impl true
  @spec render_row(term, any, boolean) :: Element.t
  def render_row(x, _, selected?) do
    table_row(if(selected?, do: @row_selected_style, else: @row_style)) do
      table_cell(content: to_string(x))
    end
  end

end
