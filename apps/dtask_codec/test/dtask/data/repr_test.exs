defmodule Tst do
  defstruct [:x, :y]
end

defmodule DTask.Data.ReprTest do
  use ExUnit.Case

  alias DTask.Data.Repr
  alias DTask.Data.Repr.Transient

  require Logger

  @moduletag :capture_log

  # doctest Repr

  @test_cases [
    nil,
    true,
    :atom,
    Atom,
    123,
    123.456e1,
    "binary",
    [],
    [1, "2"],
    [k: :v],
    %{k: :v},
    %{1 => :v},
    %{foo: nil},
    %Tst{x: 1, y: "bar"},
    %DTask.Task.DTO.Progress{label: "foo", total: 100},
    [1..10],
    DateTime.utc_now(),
    &DateTime.now/2,
    {1, 2},
    {1, "x", :test},
    {1, [k: 1], %{list: [%Tst{y: %Tst{x: &floor/1, y: nil}}]}}
  ]

  test "convert persistent data to `Repr` and back" do
    for example <- @test_cases do
      repr = Repr.to_repr(example)
      assert Repr.from_repr(repr) === {:ok, example}
    end
  end

  test "convert transient data to `Repr` and back*" do
    test_cases = [
      {:lambda,    "#Function<",  fn _ -> 1 end},
      {:pid,       "#PID<",       spawn(fn -> 1 end)},
      {:port,      "#Port<",      Port.open({:spawn, ""}, [])},
      {:reference, "#Reference<", make_ref()}
    ]
    for {type, inspect_pref, example} <- test_cases do
      repr = Repr.to_repr(example)
      {:ok, t=%Transient{}} = Repr.from_repr(repr)
      assert t.type === type
      assert String.starts_with?(t.inspect, inspect_pref)
    end
  end

end
