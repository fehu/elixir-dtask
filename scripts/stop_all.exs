#!elixir

cookie = :wnxt6nu1ipeJfRagFcCTyQKc0x3uEhLD

{:ok, host} = :inet.gethostname
ctrl_node = String.to_atom("ctrl@#{host}")
exit_code = 0

Node.start(:tmp, :shortnames)
Node.set_cookie(cookie)
Node.connect ctrl_node

:timer.sleep(500)

for node <- Node.list([:visible, :this]) do
  Node.spawn node, System, :stop, [exit_code]
end
