defmodule DTask.Task.ShellCmd do
  @moduledoc false

  require Logger

  @spec exec(
          cmd :: String.t,
          dir :: String.t,
          state0 :: state,
          handle_data :: (state, String.t -> state),
          handle_exit :: (state, integer -> out)
        ) :: out
        when state: var, out: var
  def exec(cmd, dir, state0 \\ nil, handle_data, handle_exit) do
    port = open_port(cmd, dir)
    listen_port(port, state0, handle_data, handle_exit)
  end

  defp open_port(cmd, dir) do
    Port.open {:spawn, cmd}, [
      {:cd, dir},
      :binary,
      :stderr_to_stdout,
      :exit_status
    ]
  end

  defp listen_port(port, state, handle_data, handle_exit) do
    receive do
      {^port, {:data, data}} ->
        new_state = handle_data.(state, data)
        listen_port(port, new_state, handle_data, handle_exit)
      {^port, {:exit_status, exit_code}} ->
        handle_exit.(state, exit_code)
    end
  end

end
