defmodule Expatch.Operation do
  defstruct [:op, :path, :value, :from]

  alias Expatch.Errors.{
    InvalidOperationError,
    OperationMissingValueError,
    OperationMissingFromError,
  }

  @ops ~w{add copy move replace test remove}

  def new!(map) when is_map(map) do
    op = fetch(map, :op)
    validate_op!(map, op)
    validate_value!(map, op)
    validate_from!(map, op)
    %__MODULE__{
      op: op,
      path: Expatch.Pointer.split(fetch(map, :path)),
      from: Expatch.Pointer.split(fetch(map, :from)),
      value: fetch(map, :value),
    }
  end

  defp fetch(map, field), do: map[field] || map[to_string(field)]

  defp validate_op!(map, op) when op in @ops, do: :ok
  defp validate_op!(map, op) do
    raise(InvalidOperationError, "Unrecognized op '#{op}'")
  end

  defp validate_value!(map, op) when op in ~w{add test replace},
    do: unless  has_field?(map, :value), do: raise(OperationMissingValueError)
  defp validate_value!(_map, _op), do: :ok

  defp validate_from!(map, op) when op in ~w{copy move},
    do: unless has_field?(map, :from), do: raise(OperationMissingFromError)
  defp validate_from!(_map, _op), do: :ok


  defp has_field?(map, field) do
    Map.has_key?(map, field) || Map.has_key?(map, to_string(field))
  end
end
