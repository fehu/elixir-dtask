defmodule DTask.TUI.Event.DebouncingEventManager do
  @moduledoc false

  alias ExTermbox.Event

  use GenServer

  @resize_event Ratatouille.Constants.event_type(:resize)

  @default_debounce_keys [DTask.TUI.Util.Keys.esc]

  @spec start_link(Process.dest, non_neg_integer, [integer, ...]) :: GenServer.on_start
  def start_link(manager, debounce_millis, debounce_keys \\ @default_debounce_keys),
      do: GenServer.start_link __MODULE__,
                               {manager, debounce_millis, debounce_keys},
                               name: __MODULE__

  # # # Callbacks # # #

  @impl true
  def init({manager, debounce, debounce_keys}) do
    {:ok, %{
      manager: manager,
      manager_subscribed?: false,
      debounce_ms: debounce,
      debounce_keys: debounce_keys,
      debouncing: nil,
      debounced: [],
      subscribed: []
    }}
  end

  @impl true
  def handle_call({:subscribe, subscriber_pid}, _from, state) do
    new_state_0 = if not state.manager_subscribed? do
      GenServer.call(state.manager, {:subscribe, self()})
      %{state | :manager_subscribed? => true}
    else
      state
    end

    new_state = update_in new_state_0.subscribed, fn subscribed ->
      if Enum.member?(subscribed, subscriber_pid),
         do: subscribed,
         else: [subscriber_pid | subscribed]
    end

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({:event, event}, state) do
    case event do
      %Event{type: @resize_event} ->
        notify(state, event)
        {:noreply,
          state}
      _ when not is_nil(state.debouncing) ->
        {:noreply,
          update_in(state.debounced, &[event | &1])}
      event=%Event{key: k} ->
        if k in state.debounce_keys do
          with {:ok, tref} <- :timer.send_after(state.debounce_ms, :debounce) do
            {:noreply,
              %{state | :debouncing => tref, :debounced => [event]}}
          end
        else
          notify(state, event)
          {:noreply,
            state}
        end
    end
  end
  @impl true
  def handle_info(:debounce, state) do
    msg = case state.debounced do
      [e] -> e
      es  -> {:batch, Enum.reverse(es)}
    end
    notify(state, msg)
    {:noreply,
      %{state | :debouncing => nil, :debounced => []}}
  end

  defp notify(state, event),
       do: Enum.each state.subscribed, &send(&1, {:event, event})
end
