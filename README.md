# Distributed Task Execution

- [Installation](#installation)
    + [Elixir & OTP](#elixir---otp)
    + [`epmd` & network](#-epmd----network)
- [Execution](#execution)
  * [OTP Release](#otp-release)
  * [Manually](#manually)

# Installation

### Elixir & OTP

All the nodes should use the same version of `elixir` and `erlang` (`OTP`).

Elixir version for the project is set at [`apps/dtask/mix.exs`](apps/dtask/mix.exs).

-----

We recommend to use [asdf](https://asdf-vm.com/) for managing those versions.

1. Install `asdf` as the [guide](https://asdf-vm.com/guide/getting-started.html) suggests.
2. Install `elixir` and `erlang` plugins.
   
   Refer to [asdf-elixir](https://github.com/asdf-vm/asdf-elixir) and [asdf-erlang](https://github.com/asdf-vm/asdf-erlang) guides details.
   Note that `erlang` installation has system dependencies.
 
   When the dependencies have been resolved, install the plugins.
   ```shell
   $ asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git 
   $ asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
   
   ```
3. Install `elixir` and `erlang`. 

   At the moment the project uses Elixir `1.12`.    

   `asdf` requires specifying full version of the tools to install.
   You can list versions available for installation with
   ```shell
   $ asdf list-all elixir 1.12
   ```
   _Note that Elixir versions have `-otp-` suffixes; OTP version should correspond to `erlang` installation._

   Install the latest `1.12.*` version.
   ```shell
      $ asdf install elixir <elixir version>
      # For exmaple
      $ asdf install elixir 1.12.3-otp-24
   ```

   Then install corresponding `erlang` version.

   ```shell
   $ asdf list-all erlang <OTP version>
   $ asdf install erlang <erlang version>
   # For example
   $ asdf list-all erlang 24
   $ asdf install erlang 24.1
   ```



5. If you need different tools' versions throughout your projects, `asdf` allows to specify the versions either locally or globally:
   ```shell
   $ asdf <local / global> <tool> <version>
   # For example
   $ asdf global elixir 1.12.3-otp-24
   $ asdf global erlang 24.1
   ```

### `epmd` & network
OTP cluster relies on [`Erlang Port Mapper Daemon` (`epmd`)](https://erlang.org/doc/man/epmd.html)
for establishing communication between nodes.

Note that [Erlang Distribution protocol](https://erlang.org/doc/apps/erts/erl_dist_protocol.html) is not by itself secure and does not aim to be so.
However it has a simple mechanism for preventing undesired connections by using challenge cookie.
All nodes in a cluster must share cookie value.

Connecting remote nodes requires the following ports to be opened:
  * `epmd` listen port (default: `4369`),
  * `inet_dist_listen` port range, used for direct connections between nodes.

The latter range can be specified for a node by passing following parameters to erlang vm
```shell
-kernel inet_dist_listen_min <port> inet_dist_listen_max <port>
```

-----

1. Check if `epmd` is running.
   ```shell
   $ epmd -names
   ```
2. If the daemon is running, ensure it's listening to remote hosts.
   ```shell
   sudo lsof -i -P | grep epmd
   ```
   
   It should yield either
   ```
   [1]   epmd 1234 user 4u IPv6 123456 0t0  TCP 127.0.0.1:4369 (LISTEN)
   [2]   epmd 1234 user 4u IPv6 123456 0t0  TCP *:4369 (LISTEN)
   ```
   
   In the [1] case, the daemon is listening only to local connections.
   One way to solve it is to disable `epmd` service and start the daemon manually.
   ```shell
   # Disable socket
   $ sudo systemctl stop epmd.socket
   # Disable service
   $ sudo systemctl stop epmd.service
   # Kill the daemon
   $ epmd -kill
   # Run daemon manually
   $ epmd -daemon
   ```
3. Test connections.
   
   Start two nodes on remote machines.
   ```shell
   iex --name <name>@<host> \
       --cookie <secret> \
       --erl "-kernel inet_dist_listen_min <?> inet_dist_listen_max <?>"
   ```

   Try connecting to remote node.
   ```elixir
   Node.connect :"<user>@<host>"
   # Should return `true`
   ```

# Execution

## OTP Release

1. Build releases.
   ```shell
    MIX_ENV=prod mix release ctrl
    MIX_ENV=prod mix release exec
    MIX_ENV=prod mix release tui
   ```
    
   The releases would be placed at `_build/prod` dir.

-----

The project defines scripts/links for easier interaction with releases:

* `bin/` contains shell scripts for running corresponding release executables;
* `logs/daemon` contains links to logs of the corresponding daemons.

Make `bin/` scripts executable with `chmod +x -R bin/`.

-----

2. Setup `ctrl_node` at [config/runtime/cluster.exs](config/runtime/cluster.exs).
   Replace `localhost` at `@ctrl_host` line with ip of the controller (machine where `ctrl` app is running).

3. Setup environment variables.
   ```shell
    export BEAM_HOST=<?>
    export BEAM_PORT_MIN=<?>
    export BEAM_PORT_MAX=<?>
    ```

    * `BEAM_PORT_MIN`, `BEAM_PORT_MAX` - port range to use for establishing connections with other nodes;
    * `BEAM_HOST` - hostname of the machine.

4. Run `ctrl` and/or `exec` application as daemons.
   ```shell
    bin/ctrl daemon
    bin/exec daemon
   ```
    
   For more options run `bin/<app>` without arguments.

5. Run terminal user interface.
   ```shell
    bin/tui
   ```

## Manually

### Start nodes
Enter either `apps/dtask_controller`, `apps/dtask_runner` or `apps/dtask_tui` directory.

There run
```shell
elixir --erl "-kernel inet_dist_listen_min <?> inet_dist_listen_max <?>" \
       -S mix run --no-halt

# Or
elixir --name <app>@<host> --cookie <secret> \
       --erl "-kernel inet_dist_listen_min <?> inet_dist_listen_max <?>" \
       -S mix run --no-halt
```

If node name is not specified with `--name` or `--sname`, it will be set to `<app>@<hostname>`.

If `--cookie` is not specified, it will be set to `:node_cookie` configuration value.

### Connect to master node (interactive shell)
```shell
iex --name user<host> \
    --cookie <secret> \
    --remsh ctrl@<ctrl_host>
```

Module [DTask](apps/dtask_controller/lib/dtask.ex) re-exports all controller's query functions.
  * `add_task/2`
  * `add_tasks/1`
  * `executors/0`
  * `finished?/0`
  * `resource_usage/0`
  * `tasks/0`
  * `tasks_finished/0` 
  * `tasks_pending/0`
  * `tasks_running/0`
