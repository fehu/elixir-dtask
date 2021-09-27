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
      mlm_params: params
    }}
  end
end

# # # # # # # # # # # #

config :dtask_controller, tasks: [
  Def.train_mlm,
  Def.train_mlm
]

