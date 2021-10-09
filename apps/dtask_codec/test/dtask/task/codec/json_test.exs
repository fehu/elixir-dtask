defmodule Tst1 do
  defstruct [:x, :y]
end

defmodule Tst2 do
  defstruct [:foo]
end

defmodule Tst3 do
  defstruct [:bar]
end

defmodule DTask.Task.Codec.JsonTest do
  use ExUnit.Case

  alias DTask.Task.DTO
  alias DTask.Task.Codec.Json

  import ExUnitProperties

  @moduletag :capture_log

  defmodule Gen do
    # TODO: careful with atoms generation, since atoms in erlang have a limit
    import StreamData

    def date_time do
      bind_filter positive_integer(), fn millis ->
        case DateTime.from_unix(millis) do
          {:ok, dt} -> {:cont, constant(dt)}
          _         -> :skip
        end
      end
    end

    def function do
      gen all mod   <- module(),
              name  <- atom(:alphanumeric),
              arity <- integer(0..10),
          do: Function.capture(mod, name, arity)
    end

    def module do
      gen all xs <- list_of(atom(:alias), min_length: 1, max_length: 3),
          do: Module.concat(xs)
    end

    def or_nil(data) do
      gen all b   <- boolean(),
              res <- if(b, do: data, else: constant(nil)),
          do: res
    end

    def struct_gen(max_depth, max_length), do: struct_gen(max_depth, max_depth, max_length)

    defp struct_gen(max_depth_0, max_depth, max_length),
        do: one_of([
          struct_1(max_depth_0, max_depth - 1, max_length),
          struct_2_3(max_depth_0, max_depth - 1, max_length)
        ])

    defp struct_1(max_depth_0, max_depth, max_length) do
      gen all x <- var(max_depth_0, max_depth, max_length),
              y <- var(max_depth_0, max_depth, max_length),
          do: %Tst1{x: x, y: y}
    end

    defp struct_2_3(max_depth_0, max_depth, max_length) do
      gen all x      <- var(max_depth_0, max_depth, max_length),
              {s, k} <- one_of([constant({Tst2, :foo}), constant({Tst3, :bar})]),
          do: struct(s, %{k => x})
    end

    # TODO
    # :lambda
    # :pid
    # :port
    # :reference

    def var(max_depth, max_length), do: var(max_depth, max_depth, max_length)

    def var(max_depth_0, max_depth, max_length), do: sized fn _ ->
      short = frequency [
        {100, constant(nil)},
        {1, atom(:alphanumeric)},
        {100, boolean()},
        # binary(),
        {100, float()},
        {1, function()},
        {100, integer()},
        {1, module()},
        {100, string(:printable)}
      ]
      if max_depth > 0 do
        next_var = var(max_depth_0, max_depth - 1, max_length)
        frequency([
          # max_depth_0 - max_depth
          {round(max_depth_0 / 2), short},
          {max_depth, one_of([
            list_of(next_var, min_length: 1, max_length: max_length),
            map_of(next_var, next_var, max_length: max_length),
            struct_gen(max_depth_0, max_depth - 1, max_length),
            tuple({next_var, next_var, next_var, next_var}),
            tuple({next_var, next_var, next_var}),
            tuple({next_var, next_var}),
            tuple({next_var}),
            tuple({})
          ])}
        ])
      else
        short
      end
    end

    def task(max_depth, max_length) do
      gen all id         <- integer(),
              defn       <- atom(:alias),
              params     <- var(max_depth, max_length),
              dispatched <- or_nil(dispatched()),
              finished   <- or_nil(finished(max_depth, max_length)),
          do: %DTO.Task{
            id: id,
            def: defn,
            params: DTO.Free.wrap(params),
            dispatched: dispatched,
            finished: finished
          }
    end

    def dispatched do
      gen all node      <- atom(:alphanumeric),
              timestamp <- date_time(),
          do: %DTO.Task.Dispatched{
            node: node,
            timestamp: timestamp
          }
    end

    def finished(max_depth, max_length) do
      gen all outcome   <- one_of([constant(:success), constant(:failure)]),
              result    <- var(max_depth, max_length),
              timestamp <- date_time(),
          do: %DTO.Task.Finished{
            outcome: outcome,
            result: DTO.Free.wrap(result),
            timestamp: timestamp
          }
    end

  end
  
  test "encode `DTO.Task` to JSON and back" do
    check all task <- Gen.task(10, 10),
          max_runs: 20 do
      {:ok, repr} = Json.encode(task)
      assert Json.decode(repr) === {:ok, task}
    end
  end
end
