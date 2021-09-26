defmodule DTask.Task.ShellCmd do
  @moduledoc false

  @spec exec(
          cmd :: String.t,
          dir :: String.t,
          handle_data :: (String.t -> no_return),
          handle_exit :: (non_neg_integer -> x)
        ) :: x
        when x: var
  def exec(cmd, dir, handle_data, handle_exit) do
    port = open_port(cmd, dir)
    listen_port(port, handle_data, handle_exit)
  end

  defp open_port(cmd, dir) do
    Port.open {:spawn, cmd}, [
      {:cd, dir},
      :exit_status
    ]
  end

  defp listen_port(port, handle_data, handle_exit) do
    receive do
      {^port, {:data, data}} ->
        handle_data.(data)
        listen_port(port, handle_data, handle_exit)
      {^port, {:exit_status, exit_code}} ->
        handle_exit.(exit_code)
    end
  end

end
