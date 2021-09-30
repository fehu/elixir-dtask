defmodule DTask.Task.Impl.RunMLM do
  @moduledoc false

  alias DTask.Task
  alias DTask.Task.{Reporter, ShellCmd}
  require Logger

  @behaviour Task

  @type mlm_params :: [atom | {atom, term}]
  @type params :: %{
                    required(:dir)        => String.t,
                    required(:script)     => String.t,
                    optional(:sh_opts)    => [ShellCmd.opt],
                    required(:mlm_params) => mlm_params
                  }

  @type result :: %{
                    params: %{
                      train: %{String.t => String.t},
                      eval: %{String.t => String.t}
                    },
                    metrics: %{
                      train: %{String.t => String.t},
                      eval: %{String.t => String.t}
                    }
                  }

  @typep stage :: :loading | :training | :evaluating
  @typep state :: %{
                    required(:stage)    => stage,
                    required(:capture)  => atom | [atom, ...] | nil,
                    required(:captured) => result,
                    optional(:error)    => String.t
                  }

  @spec exec(Reporter.t, params) :: {:success, result} | {:failure, term}
  def exec(reporter, params) do
    File.mkdir(Path.join(params.dir, "logs"))
    file_template = Path.join("logs", "#{params.script}.#{local_time()}.")
    info_file = file_template <> "info"
    log_file = file_template <> "log"

    script_cmd = ~s/"#{params.script}" #{mlm_params_to_string(params.mlm_params)}/
    cmd = ~s/sh run_logging.sh "#{log_file}" #{script_cmd}/

    empty_metrics_like = %{train: %{}, eval: %{}}
    state0 = %{
      stage: :loading,
      capture: nil,
      captured: %{params: empty_metrics_like, metrics: empty_metrics_like}
    }

    do_capture = fn state, txt, tip ->
      case parse_tuple(txt) do
        {k, v} ->
          Logger.debug("Capture #{tip}")
          put_in(state, [:captured] ++ state.capture ++ [k], v)
        nil ->
          state
      end
    end

    handle_data = fn state, line ->
      case parse_line(line) do
        {:info, %{file: "trainer.py", message: "***** Running training *****"}} ->
          Logger.debug("Running training")
          %{state | :stage => :training, :capture => [:params, :train]}

        {:info, %{file: "trainer.py", message: "***** Running Evaluation *****"}} ->
          Logger.debug("Running Evaluation")
          %{state | :stage => :evaluating, :capture => [:params, :eval]}

        {:info, %{file: "trainer.py", message: other}} when not is_nil state.capture ->
          do_capture.(state, other, :info)

        {:info, _} ->
          %{state | :capture => nil}

        {:progress, progress} when progress.label != "" ->
          Logger.debug("Report progress")
          Reporter.progress(reporter, progress)
          %{state | :capture => nil}

        {:progress, progress=%{label: ""}} when state.stage in [:training, :evaluating] ->
          Logger.debug("Report progress")
          Reporter.progress(reporter, %{progress | :label => state.stage})
          %{state | :capture => nil}

        {:error, error} ->
          Logger.error(error)
          Map.put(state, :error, error)

        {:mismatch, ""} when not is_nil state.capture ->
          %{state | :capture => nil}

        {:mismatch, other} when not is_nil state.capture ->
          do_capture.(state, other, :mismatch)

        {:mismatch, "***** train metrics *****"} when is_nil state.capture ->
          Logger.debug("train metrics")
          %{state | :capture => [:metrics, :train]}

        {:mismatch, "***** eval metrics *****"} when is_nil state.capture ->
          Logger.debug("eval metrics")
          %{state | :capture => [:metrics, :eval]}

        _ ->
          state
      end
    end

    handle_exit = fn
      %{error: error}, _     -> {:failure, error}
      %{captured: result}, 0 -> {:success, result}
      state, exit_code       -> {:failure, {:non_zero_exit, exit_code, state}}
    end

    # Write info file
    info_file_path = Path.join(params.dir, info_file)
    case File.write(info_file_path, inspect(params)) do
      :ok             -> :do_nothing
      {:error, error} -> Logger.warning("Failed to write file '#{info_file_path}' (#{error})")
    end

    # Execute script
    Logger.info("Executing '#{cmd}' at '#{params.dir}'")
    sh_opts = Map.get(params, :sh_opts, [])
    ShellCmd.exec(cmd, params.dir, state0, handle_data, handle_exit, sh_opts)
  end


  # # # Private functions # # #

  @typep data_info     :: %{file: String.t, message: String.t}
  @typep data_progress :: %{label: String.t, percent: String.t, step: String.t, total: String.t, time: String.t}

  @spec parse_line(String.t) :: {:info, data_info}
                              | {:progress, data_progress}
                              | {:error, String.t}
                              | {:mismatch, String.t}
  defp parse_line(data) do
    case data do
      "RuntimeError: " <> error -> {:error, error}
      "[INFO|" <> _             -> parse_line_info(data)
      _                         -> parse_line_progress(data)
    end
  end


  @regex ~r"^\[INFO\|([\w.]+):\d+\] \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3} >> (.*)$"
  defp parse_line_info(data) do
    case Regex.run(@regex, data) do
      [_, file, message] -> {:info, %{file: file, message: message}}
      _                  -> {:mismatch, data}
    end
  end

  @regex ~r"^(.+:)?\s*(\d{1,3})%\|[ █]*\| (\d+)/(\d+) \[(\d{2}:\d{2})<.*"
  defp parse_line_progress(data) do
    case Regex.run(@regex, data) do
      [_, label, percent, step, total, time] ->
        {:progress, %{label: label, percent: percent, step: step, total: total, time: time}}
      _ ->
        {:mismatch, data}
    end
  end

  @spec parse_tuple(String.t, String.t) :: {String.t, String.t} | nil
  defp parse_tuple(data, sep \\ " = ") do
    case String.split(data, sep) do
      []         -> nil
      [_]        -> nil
      [lhs, rhs] -> {String.trim(lhs), String.trim(rhs)}
      list ->
        {init, [last]} = Enum.split(list, length(list) - 1)
        {String.trim(Enum.join(init, sep)), String.trim(last)}
    end
  end

  @spec mlm_params_to_string(mlm_params) :: String.t
  defp mlm_params_to_string(params) do
    params |> Stream.map(fn
                {k, v} -> "--#{k} #{v}"
                flag   -> "--#{flag}"
              end)
           |> Enum.join(" ")
  end

  defp local_time do
    {{dy, dm, dd},{th, tm, ts}} = :calendar.local_time
    date = Enum.join([zero_pad(dy, 4), zero_pad(dm, 2), zero_pad(dd, 2)], "-")
    time = Enum.join([zero_pad(th, 2), zero_pad(tm, 2), zero_pad(ts, 2)], ":")
    date <> "--" <> time
  end

  # Copied from `Calendar.ISO`
  defp zero_pad(val, count) when val >= 0 do
    num = Integer.to_string(val)
    :binary.copy("0", max(count - byte_size(num), 0)) <> num
  end
end
