defmodule Expatch.Errors do
  defmodule OutOfBoundsUpper, do: defexception message: "index is greater than number of items in array"
  defmodule OutOfBoundsLower, do: defexception message: "index must be a positive integer"
  defmodule BadArrayKey, do: defexception message: "object operation on array target"
  defmodule ArrayIndexHasLeadingZero, do: defexception message: "array index has leading zero"
  defmodule ObjectMemberNotFoundError, do: defexception message: "object member not found"
  defmodule AddToNonExistingTargetError, do: defexception message: "add to a non-existent target"

  defmodule OperationMissingValueError,
    do: defexception [message: "operation missing value parameter"]

  defmodule OperationMissingFromError,
    do: defexception [message: "operation missing from parameter"]

  defmodule InvalidOperationError,
    do: defexception [message: "Unrecognized op"]
end
