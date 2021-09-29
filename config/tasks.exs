import Config

alias DTask.Task.Impl.RunMLM

defmodule Def do
  # # # # # # # # # # # #

  # <-------- Set `bert-test` path here
  @script_dir "path/to/bert-test/spanberta"

  @script_file "run_train.opus_2016_es.py"

  # # # # # # # # # # # #

  @spec train_mlm(RunMLM.params) :: {RunMLM, RunMLM.params}
  def train_mlm(params \\ []) do
    {RunMLM, %{
      dir: @script_dir,
      script: @script_file,
      sh_opts: [max_line_length: 16_384], # 1024 * 16
      mlm_params: params
    }}
  end
end

# # # # # # # # # # # #

config :dtask_controller, tasks: [
  Def.train_mlm [
    :do_train,
    :do_eval,
    :overwrite_output_dir,
    per_device_train_batch_size: 4,
    per_device_eval_batch_size: 8,
    max_steps: 10
  ]
]

