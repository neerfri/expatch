defmodule Expatch.SpecTests do
  defmacro __using__(_opts) do
    quote do
      Expatch.SpecTests.test_specs
      |> Enum.map(&Expatch.SpecTests.define_test(&1))
    end
  end

  defmacro define_test(test_spec) do
    quote bind_quoted: [test_spec: test_spec] do
      @tag [{:test_spec_num, to_string(test_spec["index"])}]
      case test_spec do
        %{"index" => index, "error" => error} ->
          test "#{index} - error #{error}" do
            test_spec = unquote(Macro.escape(test_spec))
            result = Expatch.apply(test_spec["doc"], test_spec["patch"])
            error = test_spec["error"]
            assert {:error, ^error} = result
          end
        %{"index" => index, "comment" => comment} ->
          test "#{index} - #{comment}" do
            test_spec = unquote(Macro.escape(test_spec))
            result = Expatch.apply(test_spec["doc"], test_spec["patch"])
            expected = Expatch.SpecTests.expected_result(test_spec)
            assert {:ok, ^expected} = result
          end
        %{"index" => index} ->
          test "#{index} - unnamed test" do
            test_spec = unquote(Macro.escape(test_spec))
            result = Expatch.apply(test_spec["doc"], test_spec["patch"])
            expected = Expatch.SpecTests.expected_result(test_spec)
            assert {:ok, ^expected} = result
          end
      end
    end
  end

  def test_specs do
    # These files are taken from: https://github.com/json-patch/json-patch-tests
    read_tests_file("tests.json")
    |> Enum.concat(read_tests_file("spec_tests.json"))
    |> Enum.with_index
    |> Enum.map(fn({test, index}) -> Map.put(test, "index", index) end)
    |> Enum.filter(&testable?/1)
    |> Enum.map(&transform_error/1)
    # |> Enum.take(80)
    # |> List.last
    # |> List.wrap
  end

  defp read_tests_file(file) do
    Path.join(__DIR__, file)
    |> File.read!()
    |> Poison.decode!()
  end

  defp testable?(%{"error" => "patch has two 'op' members"}), do: false
  defp testable?(%{"error" => "operation has two 'op' members"}), do: false
  defp testable?(_), do: true

  def expected_result(test_spec) do
    case test_spec do
      %{"expected" => expected} -> expected
      %{"patch" => ops} ->
        if Enum.all?(ops, fn(%{"op" => op}) -> op == "test" end) do
          test_spec["doc"]
        else
          raise("???")
        end
    end
  end

  defp transform_error(%{"error" => error} = test_spec) do
    Map.put(test_spec, "error", transform_error(error))
  end
  defp transform_error(%{} = test_spec), do: test_spec

  defp transform_error("index is greater than number of items in array"),
    do: "index is greater than number of items in array"
  defp transform_error("Out of bounds (upper)"),
    do: "index is greater than number of items in array"
  defp transform_error("Out of bounds (lower)"),
    do: "index must be a positive integer"
  defp transform_error("Object operation on array target"),
    do: "object operation on array target"
  defp transform_error("test op shouldn't get array element 1"),
    do: "object operation on array target"
  defp transform_error("test op should fail"),
    do: "test failed"
  defp transform_error("remove op shouldn't remove from array with bad number"),
    do: "object operation on array target"
  defp transform_error("replace op shouldn't replace in array with bad number"),
    do: "object operation on array target"
  defp transform_error("add op shouldn't add to array with bad number"),
    do: "object operation on array target"
  defp transform_error("copy op shouldn't work with bad number"),
    do: "object operation on array target"
  defp transform_error("move op shouldn't work with bad number"),
    do: "object operation on array target"
  defp transform_error("missing 'value' parameter"),
    do: "operation missing value parameter"
  defp transform_error("missing 'from' parameter"),
    do: "operation missing from parameter"
  defp transform_error("test op should reject the array value, it has leading zeros"),
    do: "array index has leading zero"
  defp transform_error("removing a nonexistent index should fail"),
    do: "index is greater than number of items in array"
  defp transform_error("removing a nonexistent field should fail"),
    do: "object member not found"
  defp transform_error("path /a does not exist -- missing objects are not created recursively"),
    do: "add to a non-existent target"
  defp transform_error("string not equivalent"),
    do: "test failed"
  defp transform_error("number is not equal to string"),
    do: "test failed"
  defp transform_error(error) when is_binary(error),
    do: error
end
