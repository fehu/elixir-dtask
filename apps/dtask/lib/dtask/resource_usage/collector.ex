defmodule DTask.ResourceUsage.Collector do
  @moduledoc false

  use GenServer
  require Logger

  @type usage0 :: %{Extractor.t => Extractor.usage}
  @type usage       :: %{node => usage0 | :dead}
  @type usage_tuple ::  {node,   usage0 | :dead}

  @spec start_link(non_neg_integer) :: GenServer.on_start
  def start_link(dead_timeout_millis) do
    Logger.debug("DTask.ResourceUsage.Collector.start_link(#{dead_timeout_millis})")
    GenServer.start_link(__MODULE__, dead_timeout_millis, name: __MODULE__)
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
      for {node, {report, time}} <- usage,
          into: %{} do
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

  # # # Notifications # # #

  defmodule Broadcast do
    @collector DTask.ResourceUsage.Collector

    @spec report_usage(term, node) :: :ok
    def report_usage(usage, node \\ Node.self()) do
      Logger.debug("DTask.ResourceUsage.Collector.Broadcast.report_usage(#{inspect(usage)}, #{inspect(node)})")
      GenServer.abcast(@collector, {:report, node, usage})
      :ok
    end
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
