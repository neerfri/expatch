defmodule Expatch do
  @moduledoc """
  An Elixir implementation of [JSON Patch](http://jsonpatch.com/)
  """

  @doc """
  Apply `operations` on `target`.

  ## Examples

      iex> Expatch.apply(%{"foo" => "bar"}, [%{op: "add", path: "/baz", value: "qux"}])
      {:ok, %{"foo" => "bar", "baz" => "qux"}}

  """
  alias Expatch.Errors.{
    AddToNonExistingTargetError,
    ArrayIndexHasLeadingZero,
    BadArrayKey,
    InvalidOperationError,
    ObjectMemberNotFoundError,
    OperationMissingFromError,
    OperationMissingValueError,
    OutOfBoundsLower,
    OutOfBoundsUpper,
  }

  @errors [
    AddToNonExistingTargetError,
    ArrayIndexHasLeadingZero,
    BadArrayKey,
    InvalidOperationError,
    ObjectMemberNotFoundError,
    OperationMissingFromError,
    OperationMissingValueError,
    OutOfBoundsLower,
    OutOfBoundsUpper,
  ]

  def apply(target, operations) when is_list(operations) do
    do_apply(target, Enum.map(operations, &Expatch.Operation.new!(&1)))
  rescue
    e in @errors ->
      {:error, e.message}
  end

  defp do_apply(target, []),
    do: {:ok, target}
  defp do_apply(target, [operation | operations]) do
    case apply_operation(target, operation) do
      {:ok, target} -> do_apply(target, operations)
      error -> error
    end
  end

  defp apply_operation(target, %{op: "add"} = op),
    do: add(target, op)
  defp apply_operation(target, %{op: "replace"} = op),
    do: replace(target, op)
  defp apply_operation(target, %{op: "remove"} = op),
    do: remove(target, op)
  defp apply_operation(target, %{op: "test"} = op),
    do: test(target, op)
  defp apply_operation(target, %{op: "move"} = op),
    do: move(target, op)
  defp apply_operation(target, %{op: "copy"} = op),
    do: copy(target, op)

  defp apply_operation(_target, _op) do
    {:error, "operation not implemented"}
  end

  defp add(_target, %{path: [], value: value}),
    do: {:ok, value}
  defp add(target, %{path: path, value: value}),
    do: {:ok, put_in(target, access_func(path, :add), value)}

  defp replace(_target, %{path: [], value: value}),
    do: {:ok, value}
  defp replace(target, %{path: path, value: value}),
    do: {:ok, put_in(target, access_func(path, :replace), value)}

  defp remove(target, %{path: path}),
    do: {:ok, pop_in(target, access_func(path, :remove)) |> elem(1)}

  defp move(target, %{path: path, from: from}) do
    {value, target} = pop_in(target, access_func(from, :remove))
    {:ok, put_in(target, access_func(path, :add), value)}
  end

  defp copy(target, %{path: path, from: from}) do
    value = get_in(target, access_func(from, :get))
    {:ok, put_in(target, access_func(path, :add), value)}
  end

  defp test(target, %{path: [], value: value}),
    do: if target == value, do: {:ok, target}, else: {:error, "test failed"}
  defp test(target, %{path: path, value: value}) do
    case get_in(target, access_func(path, :test)) do
      ^value -> {:ok, target}
      _ -> {:error, "test failed"}
    end
  end

  defp access_func([], _op), do: []
  defp access_func([field], op), do: [access_func(field, op)]
  defp access_func([field | fields], op), do: [access_func(field, nil)] ++ access_func(fields, op)
  defp access_func(field, op) do
    fn
      (:get_and_update, data, next) when is_nil(data) ->
        if op == :add, do: raise(AddToNonExistingTargetError)
        case next.(nil) do
          {get, update} -> {get, update}
        end
      (:get_and_update, data, next) when is_map(data) ->
        if op == :remove && !Map.has_key?(data, field), do: raise(ObjectMemberNotFoundError)
        {:ok, value, key} = get_string_or_atom(data, field)
        case next.(value) do
          {get, update} -> {get, Map.put(data, key, update)}
          :pop -> Map.pop(data, key)
        end

      (:get, data, next) when is_map(data) ->
        {:ok, value, _key} = get_string_or_atom(data, field)
        next.(value)

      (:get_and_update, data, next) when is_list(data) ->
        index = parse_list_index(field, op, length(data))
        case next.(Enum.at(data, index)) do
          {get, update} ->
            case op do
              :add -> {get, List.insert_at(data, index, update)}
              _ -> {get, List.replace_at(data, index, update)}
            end
          :pop -> List.pop_at(data, index)
        end

      (:get, data, next) when is_list(data) ->
        next.(Enum.at(data, to_array_index(field)))
    end
  end

  defp parse_list_index(field, op, list_length)
  defp parse_list_index("-", :add, _), do: -1
  defp parse_list_index(field, op, list_length) when is_binary(field),
    do: parse_list_index(to_array_index(field), op, list_length)
  defp parse_list_index(index, _op, _) when is_integer(index) and index < 0,
    do: raise(OutOfBoundsLower)
  defp parse_list_index(index, op, list_length)
    when is_integer(index) and index >= list_length and op in [:remove, :replace],
    do: raise(OutOfBoundsUpper)
  defp parse_list_index(index, _op, list_length)
    when is_integer(index) and index > list_length,
    do: raise(OutOfBoundsUpper)
  defp parse_list_index(index, _, _),
    do: index

  defp to_array_index(field) when is_binary(field) do
    if Regex.match?(~r{[0]+[0-9]}, field), do: raise(ArrayIndexHasLeadingZero)
    String.to_integer(field)
  rescue
    ArgumentError -> raise(BadArrayKey)
  end

  defp get_string_or_atom(map, field) when is_binary(field) do
    case Map.fetch(map, field) do
      {:ok, value} -> {:ok, value, field}
      :error ->
        case to_existing_atom(field) do
          {:ok, key} ->
            case Map.fetch(map, key) do
              {:ok, value} -> {:ok, value, key}
              :error -> {:ok, nil, field}
            end
          :error -> {:ok, nil, field}
        end
    end
  end

  defp to_existing_atom(string) do
    try do
      {:ok, String.to_existing_atom(string)}
    rescue
      ArgumentError -> :error
    end
  end
end
