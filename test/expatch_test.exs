defmodule ExpatchTest do
  use ExUnit.Case
  use Expatch.SpecTests
  doctest Expatch

  defmodule TestStruct, do: defstruct [:my_attribute, my_list: []]

  test "updating a struct" do
    result = Expatch.apply(%TestStruct{}, [
      %{"op" => "replace", "path" => "/my_attribute", "value" => "my_val"}
    ])
    assert {:ok, %TestStruct{my_attribute: "my_val"}} = result
  end

  test "updating a list in a struct" do
    result = Expatch.apply(%TestStruct{}, [
      %{"op" => "add", "path" => "/my_list/-", "value" => "my_list_val"}
    ])
    assert {:ok, %TestStruct{my_list: ["my_list_val"]}} = result
  end
end
