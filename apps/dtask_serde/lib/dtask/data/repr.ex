defmodule DTask.Data.Repr do
  @moduledoc """
  Generic representation of Elixir's data structures.
  """

  defmodule Transient do
    @enforce_keys [:type]
    defstruct [:type, :inspect]

    @type t :: %__MODULE__{
                 type: atom,
                 inspect: String.t
               }
  end

  # # # # # # # # # # # # # # # # # # # #

  alias DTask.Util.ReprUtils, as: Utils

  @enforce_keys [:type]
  defstruct     [:type, :children, :self]

  @type atomic :: boolean | binary | nil | number

  @typep t_leaf :: atomic
                 | %__MODULE__{
                     type: type,
                     self: atomic
                   }
  @typep t_node :: %__MODULE__{
                     type: type,
                     children: [t, ...]
                   }
  @type t :: t_node | t_leaf

  @type type :: :atom
              | :boolean
              | :binary
              | :function
              | :lambda
              | :list
              | :map
              | :nil
              | :number
              | :pid
              | :port
              | :reference
              | :struct
              | :tuple

  # # # # # # # # # # # # # # # # # # # #

  @type_checks [
    # Atoms
    {:nil,       &Utils.is_nil/1},
    {:boolean,   &Kernel.is_boolean/1},
    {:atom,      &Kernel.is_atom/1},
    # Data
    {:number,    &Kernel.is_number/1},
    {:binary,    &Kernel.is_binary/1},
    # Tuples
    {:tuple,     &Kernel.is_tuple/1},
    # Collections
    {:list,      &Kernel.is_list/1},
    {:struct,    &Utils.is_struct/1},
    {:map,       &Kernel.is_map/1},
    # Misc
    {:function,  &Kernel.is_function/1},
    {:pid,       &Kernel.is_pid/1},
    {:port,      &Kernel.is_port/1},
    {:reference, &Kernel.is_reference/1}
  ]

  @atomic    [:boolean, :binary, :nil, :number]
  @transient [:lambda, :pid, :port, :reference]

  @type from_out :: {:ok, term}
                  | {:ok, __MODULE__.Transient.t}
                  | {:error, term}
                  | {:failed, [from_out]}

  @spec from(t) :: from_out
  def from(a) when is_boolean(a) or is_binary(a) or is_nil(a) or is_number(a),
      do: {:ok, a}

  def from(%__MODULE__{type: :atom, self: a}),
      do: {:ok, String.to_atom(a)}

  def from(%__MODULE__{type: :list, children: elems}),
      do: collect(elems, &from/1)

  def from(%__MODULE__{type: :map, children: entries}) do
    with {:ok, list}  <- collect(entries, &from/1),
         {:ok, pairs} <- collect(list, &safe_pair/1),
      do: {:ok, Map.new(pairs)}
  end

  def from(%__MODULE__{type: :struct, children: [name | fields]}) when is_binary(name) do
    with {:ok, map} <- from(%__MODULE__{type: :map, children: fields}),
      do: safe_struct(name, map)
  end

  def from(%__MODULE__{type: :tuple, children: elems}) do
    with {:ok, list} <- collect(elems, &from/1),
      do: {:ok, List.to_tuple(list)}
  end

  def from(%__MODULE__{type: :function, children: [mod, name, arity]})
      when is_binary(mod) and is_binary(name) and is_integer(arity),
      do: {:ok, Function.capture(String.to_atom(mod), String.to_atom(name), arity)}

  def from(%__MODULE__{type: t, self: inspect}) when t in @transient,
      do: {:ok, %__MODULE__.Transient{type: t, inspect: inspect}}

  def from(other),
      do: {:error, {:unsupported, other}}

  defp collect(coll, f) do
    result = Enum.map(coll, &f.(&1))
    has_error? = Enum.any? result, fn
      {:error, _}  -> true
      {:failed, _} -> true
      _            -> false
    end
    unless has_error?,
           do: {:ok, Enum.map(result, &elem(&1, 1))},
           else: {:failed, result}
  end

  defp safe_struct(name, fields) do
    try do
      {:ok, struct(String.to_atom(name), fields)}
    rescue
      e -> {:error, e}
    end
  end

  defp safe_pair(t={_, _}), do: {:ok, t}
  defp safe_pair(other),    do: {:error, "Not a pair: #{inspect other}"}

  @spec to(term) :: t
  def to(x), do: make_repr(type(x), x)

  @spec type(term) :: type
  def type(x), do: @type_checks |> Enum.find(fn {_, test} -> test.(x) end) |> elem(0)

  defp make_repr(t, x) when t in @atomic,    do: x
  defp make_repr(t, x) when t in @transient, do: leaf(t, inspect(x))
  defp make_repr(:struct, s),
       do: node(:struct, [
         to_string(s.__struct__)
         | make_repr(:map, Map.from_struct(s)).children])
  defp make_repr(:atom, a),    do: leaf(:atom,  a |> Atom.to_string)
  defp make_repr(:list, l),    do: node(:list,  l |> Enum.map(&to/1))
  defp make_repr(:map, m),     do: node(:map,   m |> Enum.map(&make_repr(:tuple, &1)))
  defp make_repr(:tuple, t),   do: node(:tuple, t |> Tuple.to_list |> Enum.map(&to/1))
  defp make_repr(:function, f) do
    info = Function.info(f)
    case info[:type] do
      :external ->
        node(:function, [
          Atom.to_string(info[:module]),
          Atom.to_string(info[:name]),
          info[:arity]
        ])
      :local ->
        leaf(:lambda, inspect(f))
    end
  end

  defp leaf(type, self),     do: %__MODULE__{type: type, self: self}
  defp node(type, children), do: %__MODULE__{type: type, children: children}
end

alias DTask.Data.Repr.Transient

defimpl String.Chars, for: Transient do
  def to_string(%Transient{inspect: txt}), do: txt
  def to_string(%Transient{type: type}),   do: "##{type}"
end
