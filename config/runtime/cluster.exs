# #
# # Runtime configuration template. Do not commit it.
# #

defmodule Cluster do
  @ctrl_host "localhost"

  @ctrl_node String.to_atom("ctrl@" <> @ctrl_host)

  def ctrl_node, do: @ctrl_node
end
