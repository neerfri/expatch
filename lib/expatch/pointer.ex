defmodule Expatch.Pointer do
  def split(nil), do: nil
  def split(""), do: []
  def split("/"), do: [""]
  def split("/" <> path) do
    path
    |> String.split("/")
    |> Enum.map(&unescape(&1))
  end

  defp unescape(path_part) when is_binary(path_part) do
    path_part
    |> String.replace("~1", "/")
    |> String.replace("~0", "~")
  end
end
