defmodule DTask.Task.ShellCmd do
  @moduledoc false

  require Logger

  @type opt :: {:max_line_length, non_neg_integer}

  @default_max_line_length 1024

  @spec exec(
          cmd :: String.t,
          dir :: String.t,
          state0 :: state,
          handle_data :: (state, String.t -> state),
          handle_exit :: (state, integer -> out),
          opts :: [opt]
        ) :: out
        when state: var, out: var
  def exec(cmd, dir, state0 \\ nil, handle_data, handle_exit, opts \\ []) do
    port = open_port(cmd, dir, opts)
    listen_port(port, state0, handle_data, handle_exit)
  end

  defp open_port(cmd, dir, opts) do
    max_line_length = Keyword.get(opts, :max_line_length, @default_max_line_length)
    Port.open {:spawn, cmd}, [
      {:cd, dir},
      :binary,
      {:line, max_line_length},
      :stderr_to_stdout,
      :exit_status
    ]
  end

  defp listen_port(port, state, handle_data, handle_exit) do
    receive do
      {^port, {:data, {l_flag, line}}} ->
        if l_flag == :noeol, do:
          Logger.warning("Output line length exceeds the limit, it will be split.")
        new_state = handle_data.(state, line)
        listen_port(port, new_state, handle_data, handle_exit)
      {^port, {:exit_status, exit_code}} ->
        handle_exit.(state, exit_code)
    end
  end

end
