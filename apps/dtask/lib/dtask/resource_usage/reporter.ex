defmodule DTask.ResourceUsage.Reporter do
  @moduledoc false

  alias DTask.ResourceUsage.{Collector, Extractor}

  use GenServer
  require Logger

  @spec start_link(
          collector :: GenServer.server,
          interval :: non_neg_integer,
          extractor :: Extractor.t,
          extractor_params :: Extractor.params,
          register :: :register | nil
        ) :: GenServer.on_start
  def start_link(collector, interval, extractor, extractor_params, register \\ nil) do
    Logger.debug("DTask.ResourceUsage.Reporter.start_link")
    init = {collector, interval, extractor, extractor_params}
    opts = if register == :register,
              do: [name: __MODULE__],
              else: []
    GenServer.start_link(__MODULE__, init, opts)
  end

  @spec stop(GenServer.server) :: :ok
  def stop(reporter) do
    GenServer.stop(reporter)
  end

  # Can be used if the `Reporter` has been registered at `start_link`
  @spec stop() :: :ok
  def stop() do
    GenServer.stop(__MODULE__)
  end

  # # # Callbacks # # #

  @impl GenServer
  def init(state={_collector, interval, _extractor, _extractor_params}) do
    schedule_report(interval)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:report, state={collector, interval, extractor, extractor_params}) do
    Logger.debug("DTask.ResourceUsage.Reporter.handle_info :report")
    with {:ok, usage} <- extractor.query_usage(extractor_params),
         _ <- Collector.report_usage(collector, usage),
         _ <- schedule_report(interval),
      do: {:noreply, state}
  end

  defp schedule_report(interval) do
    Process.send_after(self(), :report, interval)
  end

end
