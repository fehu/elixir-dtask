# #
# # Runtime configuration template. Do not commit it.
# #

alias DTask.Task.Impl.RunMLM

defmodule Tasks do
  # # # # # # # # # # # #

  # <-------- Set `bert-test` path here
  @script_dir "path/to/bert-test/spanberta"

  @script_file "run_train.opus_2016_es.py"

  @spec local_config :: %{module => %{atom => term}}
  def local_config, do: %{
    RunMLM => %{
      dir: @script_dir,
      script: @script_file,
    }
  }
  # # # # # # # # # # # #

  @spec train_mlm(RunMLM.params) :: {RunMLM, RunMLM.params}
  def train_mlm(params \\ []) do
    {RunMLM, %{mlm_params: params}}
  end

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
                      # # # Tasks # # #
                      # # # # # # # # #

  def get, do: [
    train_mlm [
      :do_train,
      :do_eval,
      :overwrite_output_dir,
      per_device_train_batch_size: 4,
      per_device_eval_batch_size: 8,
      max_steps: 10
    ]
  ]
end
