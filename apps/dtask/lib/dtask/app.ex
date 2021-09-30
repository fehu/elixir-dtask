defmodule DTask.App do
  @moduledoc false

  require Logger

  @spec ensure_node_alive!(Access.t, atom) :: node
  def ensure_node_alive!(cfg, node_prefix_key) do
    case ensure_node_alive(cfg, node_prefix_key) do
      {:ok, node}     -> node
      {:error, error} -> raise error
    end
  end

  @spec ensure_node_alive(Access.t, atom) :: {:ok, node} | {:error, term}
  def ensure_node_alive(cfg, node_prefix_key) do
    unless Node.alive? do
      with {:ok, host} <- :inet.gethostname,
           node = String.to_atom(cfg[node_prefix_key] <> "@" <> List.to_string(host)),
           {:ok, _pid} <- Node.start(node, :shortnames)
        do
          Node.set_cookie(node, cfg.node_cookie)
          Logger.notice("Started node #{node}")
          {:ok, node}
        end
    else
      Logger.info("Node already alive: #{Node.self()}")
      {:ok, Node.self()}
    end
  end

end
