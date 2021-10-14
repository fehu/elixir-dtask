defmodule DTask.TUI.Util do
  @moduledoc false

  @app_name :dtask_tui

  @timezone_database Tzdata.TimeZoneDatabase

  def timezone, do: Application.fetch_env!(@app_name, :timezone)
  def timezone_database, do: @timezone_database

  def shift_time_zone(t) when is_struct(t, DateTime),
      do: DateTime.shift_zone!(t, timezone(), @timezone_database)

  def now_local(), do: DateTime.now!(timezone, timezone_database)
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
  @insert      Constants.key(:insert)
  @delete      Constants.key(:delete)

  @space       Constants.key(:space)
  @backspace   Constants.key(:backspace2)
  @enter       Constants.key(:enter)
  @tab         Constants.key(:tab)
  @esc         Constants.key(:esc)

  @ctrl_backspace Constants.key(:backspace)
  @ctrl_c         Constants.key(:ctrl_c)
  @ctrl_d         Constants.key(:ctrl_d)
  @ctrl_e         Constants.key(:ctrl_e)
  @ctrl_q         Constants.key(:ctrl_q)
  @ctrl_w         Constants.key(:ctrl_w)

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
      @insert      unquote @insert
      @delete      unquote @delete

      @space       unquote @space
      @backspace   unquote @backspace
      @enter       unquote @enter
      @tab         unquote @tab
      @esc         unquote @esc

      @ctrl_backspace unquote @ctrl_backspace
      @ctrl_c         unquote @ctrl_c
      @ctrl_d         unquote @ctrl_d
      @ctrl_e         unquote @ctrl_e
      @ctrl_q         unquote @ctrl_q
      @ctrl_w         unquote @ctrl_w
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
  def insert,      do: @insert
  def delete,      do: @delete

  def space,       do: @space
  def backspace,   do: @backspace
  def enter,       do: @enter
  def tab,         do: @tab
  def esc,         do: @esc

  def ctrl_backspace, do: @ctrl_backspace
  def ctrl_c,         do: @ctrl_c
  def ctrl_d,         do: @ctrl_d
  def ctrl_e,         do: @ctrl_e
  def ctrl_q,         do: @ctrl_q
  def ctrl_w,         do: @ctrl_w
end

defmodule DTask.TUI.Util.Escaped do
  alias DTask.TUI.Util.Keys

  @ctrl_arrow_up_esc    {Keys.esc, [91, 49, 59, 53, 65]}
  @ctrl_arrow_down_esc  {Keys.esc, [91, 49, 59, 53, 66]}
  @ctrl_arrow_left_esc  {Keys.esc, [91, 49, 59, 53, 68]}
  @ctrl_arrow_right_esc {Keys.esc, [91, 49, 59, 53, 67]}
  @ctrl_delete_esc      {Keys.esc, [91, 51, 59, 53, 126]}

  defmacro __using__(_) do
    quote do
      @ctrl_arrow_up_esc    unquote @ctrl_arrow_up_esc
      @ctrl_arrow_down_esc  unquote @ctrl_arrow_down_esc
      @ctrl_arrow_right_esc unquote @ctrl_arrow_right_esc
      @ctrl_arrow_left_esc  unquote @ctrl_arrow_left_esc
      @ctrl_delete_esc      unquote @ctrl_delete_esc
    end
  end

  def ctrl_arrow_up_esc,    do: @ctrl_arrow_up_esc
  def ctrl_arrow_down_esc,  do: @ctrl_arrow_down_esc
  def ctrl_arrow_right_esc, do: @ctrl_arrow_right_esc
  def ctrl_arrow_left_esc,  do: @ctrl_arrow_left_esc
  def ctrl_delete_esc,      do: @ctrl_delete_esc
end
