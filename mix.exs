defmodule Expatch.Mixfile do
  use Mix.Project

  def project do
    [app: :expatch,
     version: "0.1.0",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     docs: docs(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:poison, ">= 0.0.0", only: [:test, :dev]},
    ]
  end

  defp description do
    """
    An Elixir implementation of JSON Patch http://jsonpatch.com/
    """
  end

  defp package() do
    [
      maintainers: ["Neer Friedman"],
      licenses: ["MIT"],
      files: ~w(mix.exs README.md lib),
      links: %{"GitHub" => "https://github.com/neerfri/expatch"}
    ]
  end

  defp docs() do
    [
      main: "readme",
      extras: ["README.md"],
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

end
