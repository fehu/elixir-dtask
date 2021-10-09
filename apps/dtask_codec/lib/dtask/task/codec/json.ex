alias DTask.Data.Repr
alias DTask.Task.DTO

defmodule DTask.Task.Codec.Json do
  @moduledoc false

  alias DTask.Task.Codec

  import DTask.Util.ReprUtils, only: [collect_arr: 1]
  import DTask.Util.Syntax

  require Repr

  @behaviour Codec

  @type repr :: iodata

  @impl true
  @spec encode(DTO.Task.t) :: Codec.result(repr)
  def encode(dto), do: Jason.encode_to_iodata(dto)

  @impl true
  @spec decode(repr) :: Codec.result(DTO.Task.t)
  def decode(repr) do
    with {:ok, raw}        <- Jason.decode(repr),
         :ok               <- ensure_is_map(raw, :decode),
         {:ok, id}         <- get(raw, :id),
         :ok               <- ensure_is_int(id),
         {:ok, task_def}   <- get(raw, :def),
         {:ok, params}     <- get(raw, :params, :optional),
         {:ok, params}     <- decode_repr(params),
         {:ok, params}     <- Repr.from_repr(params),
         {:ok, dispatched} <- get(raw, :dispatched, :optional),
         {:ok, dispatched} <- maybe(dispatched, &decode_dispatched/1) <|> {:ok, nil},
         {:ok, finished}   <- get(raw, :finished, :optional),
         {:ok, finished}   <- maybe(finished, &decode_finished/1) <|> {:ok, nil},
      do: {:ok, %DTO.Task{
        id: id,
        def: String.to_atom(task_def),
        params: DTO.Free.wrap(params),
        dispatched: dispatched,
        finished: finished
      }}
  end

  defp decode_dispatched(raw) do
    with :ok         <- ensure_is_map(raw, :decode_dispatched),
         {:ok, node} <- get(raw, :node),
         {:ok, time} <- get(raw, :timestamp),
         {:ok, time} <- decode_timestamp(time),
      do: {:ok, %DTO.Task.Dispatched{
        node: String.to_atom(node),
        timestamp: time
      }}
  end

  defp decode_finished(raw) do
    with :ok         <- ensure_is_map(raw, :decode_finished),
         {:ok, out}  <- get(raw, :outcome),
         {:ok, out}  <- (case String.to_atom(out) do
                           out when out in [:success, :failure] -> {:ok, out}
                           other -> {:error, "Not an outcome: #{other}"}
                         end),
         {:ok, res}  <- get(raw, :result, :optional),
         {:ok, res}  <- decode_repr(res),
         {:ok, res}  <- Repr.from_repr(res),
         {:ok, time} <- get(raw, :timestamp),
         {:ok, time} <- decode_timestamp(time),
      do: {:ok, %DTO.Task.Finished{
        outcome: out,
        result: DTO.Free.wrap(res),
        timestamp: time
      }}
  end

  @spec decode_repr(term) :: Codec.result(Repr.t)
  def decode_repr(a) when Repr.is_atomic(a),
      do: {:ok, a}
  def decode_repr(%{"type" => type, "self" => self, "children" => xs})
      when is_binary(type)
       and (Repr.is_atomic(self))
       and (is_list(xs) or is_nil(xs))
    do
      with {:ok, children} <- maybe(xs, collect_arr(&decode_repr/1)) <|> {:ok, nil},
        do: {:ok, %Repr{
          type: String.to_atom(type),
          self: self,
          children: children
        }}
  end

  defp decode_timestamp(s) do
    with {:ok, dt, 0} <- DateTime.from_iso8601(s) do
      {:ok, dt}
    else _ ->
      {:error, "Failed to parse timestamp from #{inspect s}"}
    end
  end

  defp get(map, key, opt \\ nil) do
    maybe(Map.get(map, to_string(key)), &{:ok, &1})
    <|> case opt do
          :optional -> {:ok, nil}
          _         -> {:error, "Key '#{key}' not in #{inspect map}"}
        end
  end

  defmacrop ensure_is(name_tip, x, cond, tip \\ nil) do
    tip_str = case tip do
      nil -> quote do: ""
      _   -> quote do: "[#{unquote tip}] "
    end
    quote do
      if unquote(cond).(unquote(x)),
         do: :ok,
         else: {:error, "#{unquote tip_str}Not #{unquote name_tip}: #{inspect unquote(x)}"}
    end
  end

  defp ensure_is_int(x),       do: ensure_is("int",      x, &is_integer/1)
  defp ensure_is_map(x, tip),  do: ensure_is("map",      x, &is_map/1, tip)

end

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # Implement `Encoder` for `DTO.Free`  # # #

defimpl Jason.Encoder, for: DTO.Free do
  @spec encode(DTO.Free.t, Jason.Encoder.opts) :: iodata
  def encode(%DTO.Free{data: data}, _) do
    case Jason.encode_to_iodata(Repr.to_repr(data)) do
      {:ok, data} -> data
      {:error, e} -> raise "Error: #{inspect e}"
    end
  end
end

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # Derive `Encoder` for `DTO.Task` and `Data.Repr`. # # #

require Protocol

Protocol.derive(Jason.Encoder, DTO.Task)
Protocol.derive(Jason.Encoder, Repr)
