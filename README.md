# Expatch

An Elixir implementation of [JSON Patch](http://jsonpatch.com/)

## Installation

add `expatch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:expatch, "~> 0.1.0"},
  ]
end
```

## Usage

```elixir
Expatch.apply(%{foo: "bar"}, [%{op: "add", path: "/baz", value: "qux"}])
```
