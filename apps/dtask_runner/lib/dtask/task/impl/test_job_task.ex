defmodule DTask.Task.Impl.TestJobTask do
  @moduledoc false

  alias DTask.Task
  alias DTask.Task.{Reporter, ShellCmd}
  alias DTask.Task.DTO.Progress

  require Logger

  @behaviour Task

  @type local_params :: %{
                          elixir_cmd: String.t | :asdf
                        }
  @type params :: %{
                    optional(:steps) => non_neg_integer,
                    optional(:wait)  => non_neg_integer
                  }

  @regex ~r"^\s*(.*): (\d+) / (\d+)\s*$"
  @spec exec(Reporter.t, local_params, params) :: {:success, term} | {:failure, term}
  def exec(reporter, local_params, params) do
    elixir_cmd = case local_params.elixir_cmd do
      :asdf -> asdf_elixir_cmd()
      cmd   -> cmd
    end
    cmd_params = case params do
      %{steps: s, wait: w} -> " #{s} #{w}"
      %{steps: s}          -> " #{s}"
      _                    -> ""
    end
    script_file = Path.join(["apps", "dtask_runner", "dev", "test_job.exs"])

    cmd = elixir_cmd <> " " <> script_file <> cmd_params
    dir = "."

    Logger.debug("Executing '#{cmd}' in '#{dir}'")

    handle_data = fn
      _, data ->
        case Regex.run(@regex, data) do
          [_, label, step, total] ->
            Reporter.progress(reporter, Progress.new(label, step, total))
          _ -> nil
        end
    end
    handle_exit = fn
      _, 0 -> {:success, "done"}
      _, c -> {:failure, {:non_zero_exit, c}}
    end
    ShellCmd.exec(cmd, dir, handle_data, handle_exit)
  end

  defp asdf_elixir_cmd() do
    with {erl_root_0, 0} <- System.cmd("asdf", ["where", "erlang"]),
         {elixir_0,   0} <- System.cmd("asdf", ["which", "elixir"]) do
      erl_root  = String.trim(erl_root_0)
      elixir    = String.trim(elixir_0)
      boot_file = Path.join([erl_root, "bin", "start"])

      "#{elixir} --boot #{boot_file}"
    else
      _ -> raise "Failed to find asdf installations of Elixir and/or Erlang"
    end
  end
end
