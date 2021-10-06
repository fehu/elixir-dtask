defmodule DTask.App do
  @moduledoc false

  require Logger

  @spec ensure_node_alive!(Access.t, atom) :: node
  def ensure_node_alive!(cfg, node_prefix_key) do
    case ensure_node_alive(cfg, node_prefix_key) do
      {:ok, node}     -> node
      {:error, error} -> raise __MODULE__.StartupError, error
    end
  end

  @spec ensure_node_alive(Access.t, atom) :: {:ok, node} | {:error, term}
  def ensure_node_alive(cfg, node_prefix_key) do
    case :net_kernel.epmd_module.names do
      {:error, _} -> {:error, :no_epmd}
      {:ok, _}    -> start_unless_alive(cfg, node_prefix_key)
    end
  end

  defp start_unless_alive(cfg, node_prefix_key) do
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

  defmodule StartupError do
    defexception [:reason]

    @impl true
    def exception(any), do: %__MODULE__{reason: any}

    @net_kernel_shutdown {:shutdown, {:failed_to_start_child, :net_kernel, {:EXIT, :nodistribution}}}

    @impl true
    def message(error) do
      case error.reason do
        :no_epmd ->
          "Failed to connect to EPMD. Ensure it is running by executing `epmd -daemon`."
        {@net_kernel_shutdown,
          {_, _, _, {:erl_distribution, :start_link, [[node, _, _], _, _]}, _, _, _, _, _}
        } ->
          "The name '#{node}' seems to be in use by another Erlang node."
        other ->
          "Unexpected error: #{inspect(other)}"
      end
    end
  end
end
