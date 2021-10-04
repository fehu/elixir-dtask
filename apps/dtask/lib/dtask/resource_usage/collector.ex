defmodule DTask.ResourceUsage.Collector do
  @moduledoc false

  use GenServer
  require Logger

  @type usage :: %{node => term}

  @spec start_link(non_neg_integer) :: GenServer.on_start
  def start_link(dead_timeout_millis) do
    Logger.debug("DTask.ResourceUsage.Collector.start_link(#{dead_timeout_millis})")
    GenServer.start_link(__MODULE__, dead_timeout_millis, name: __MODULE__)
  end

  @spec report_usage(GenServer.server, term) :: :ok
  def report_usage(server, usage) do
    Logger.debug("DTask.ResourceUsage.Collector.report_usage(#{inspect(server)}, #{inspect(usage)})")
    GenServer.cast(server, {:report, Node.self(), usage})
  end

  @spec get_usage(GenServer.server) :: usage
  def get_usage(server \\ __MODULE__) do
    Logger.debug("DTask.ResourceUsage.Collector.get_usage(#{inspect(server)})")
    GenServer.call(server, :get)
  end

  # # # Callbacks # # #

  @impl true
  def init(dead_timeout) do
    cfg = %{dead_timeout: dead_timeout}
    usage0 = %{}
    {:ok, {cfg, usage0}}
  end

  @impl true
  def handle_call(:get, _from, {cfg, usage}) do
    now = System.monotonic_time(1_000)
    response =
      for {node, {report, time}} <- usage do
        if now - time > cfg.dead_timeout,
          do: {node, :dead},
          else: {node, report}
      end
    {:reply, response, {cfg, usage}}
  end

  @impl true
  def handle_cast({:report, node, report}, {cfg, usage}) do
    now = System.monotonic_time(1_000)
    usage_upd = Map.put(usage, node, {report, now})
    {:noreply, {cfg, usage_upd}}
  end

end

defmodule DTask.ResourceUsage.Collector.CLI do
  defmacro __using__(_) do
    quote do
      alias DTask.ResourceUsage.Collector

      defdelegate resource_usage(), to: Collector, as: :get_usage
    end
  end
end
