import Config

alias DTask.Task.Impl.TestJobTask

config :dtask_controller, tasks: [
  {TestJobTask, "123"},
  {TestJobTask, "456"}
]

