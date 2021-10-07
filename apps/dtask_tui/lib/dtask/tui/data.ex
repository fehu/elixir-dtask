defprotocol DTask.TUI.Data do
  @fallback_to_any true
  @spec save(t) :: [{id :: term, term}]
  def save(data)
end

defimpl DTask.TUI.Data, for: Map do
  defdelegate save(data), to: Map, as: :to_list
end

defimpl DTask.TUI.Data, for: DTask.Task.Monitor.State do
  def save(data), do:
    Map.merge(data.def_of, data.state_of, fn _, x, y -> {x, y} end)
    |> Map.to_list
end

defimpl DTask.TUI.Data, for: Any do
  def save(_), do: []
end
