defmodule DTask.TUI.Util do
  @moduledoc false

  @app_name :dtask_tui

  @timezone_database Tzdata.TimeZoneDatabase

  def timezone, do: Application.fetch_env!(@app_name, :timezone)
  def timezone_database, do: @timezone_database

  def shift_time_zone(t) when is_struct(t, DateTime),
      do: DateTime.shift_zone!(t, timezone(), @timezone_database)

end

defmodule DTask.TUI.Util.Keys do
  alias Ratatouille.Constants

  @arrow_up    Constants.key(:arrow_up)
  @arrow_down  Constants.key(:arrow_down)
  @arrow_left  Constants.key(:arrow_left)
  @arrow_right Constants.key(:arrow_right)
  @page_up     Constants.key(:pgup)
  @page_down   Constants.key(:pgdn)
  @home        Constants.key(:home)
  @end_        Constants.key(:end)

  defmacro __using__(_) do
    quote do
      @arrow_up    unquote @arrow_up
      @arrow_down  unquote @arrow_down
      @arrow_left  unquote @arrow_left
      @arrow_right unquote @arrow_right
      @page_up     unquote @page_up
      @page_down   unquote @page_down
      @home        unquote @home
      @end_        unquote @end_
    end
  end

  def arrow_up,    do: @arrow_up
  def arrow_down,  do: @arrow_down
  def arrow_left,  do: @arrow_left
  def arrow_right, do: @arrow_right
  def page_up,     do: @page_up
  def page_down,   do: @page_down
  def home,        do: @home
  def end_,        do: @end_
end
