# Distributed Task Execution

## TODO

* Introduce `task_id` and use it for reports instead of `{Task.t, Task.params}` pair.

* Define `Progress` struct (but don't restrict `Reporter.progress`, or add other func).

* Use `call` to ensure task was accepted for execution at `Executor.exec_task`.
