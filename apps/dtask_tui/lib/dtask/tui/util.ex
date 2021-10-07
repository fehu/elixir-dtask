defmodule DTask.TUI.Util do
  @moduledoc false

  @moduledoc false

  @app_name :dtask_tui

  @timezone_database Tzdata.TimeZoneDatabase

  def timezone, do: Application.fetch_env!(@app_name, :timezone)
  def timezone_database, do: @timezone_database

  def shift_time_zone(t) when is_struct(t, DateTime),
      do: DateTime.shift_zone!(t, timezone(), @timezone_database)

end
