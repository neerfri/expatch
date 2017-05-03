defmodule Mix.Tasks.GetTest do
  use Mix.Task
  @preferred_cli_env :test

  def run([num]) do
    Path.join(__DIR__, "../../../test/support/spec_tests.ex")
    |> Path.expand
    |> Code.require_file()

    {:module, _} = Code.ensure_loaded(Poison)
    requested_index = String.to_integer(num)

    Expatch.SpecTests.test_specs
    |> Enum.find(fn(%{"index" => index}) -> index == requested_index end)
    |> IO.inspect()
  end
end
