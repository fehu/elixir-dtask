# DTask

**TODO: Add description**

## Installation

### Open ports
 * `epmd` (default: `4369`),
 * Range `inet_dist_listen_min`-`inet_dist_listen_max`.

### Expose `epmd`
Execute
```shell
sudo lsof -i -P | grep epmd
```

It should yield either
```
[1] epmd      1234    user    4u  IPv6 123456      0t0  TCP 127.0.0.1:4369 (LISTEN)

[2] epmd      1234    user    4u  IPv6 123456      0t0  TCP *:4369 (LISTEN)
```

In the [1] case, you should disable `epmd` service at start it manually.
```shell

$ sudo systemctl stop epmd.socket
$ sudo service epmd stop
$ epmd -kill

# epmd -debug
$ epmd -daemon
```

### Node

Start a node.
```shell
iex --name <name>@<host> \
    --cookie <secret> \
    --erl "-kernel inet_dist_listen_min <?> inet_dist_listen_max <?>"

```

Connect to remote node.
```elixir
Node.connect :"<user>@<host>"
```

