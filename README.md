# FnFlow

**TODO: Add description**
- [X] remove try-catch in loop function

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `fnflow` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fnflow, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/fnflow](https://hexdocs.pm/fnflow).


## Example
```elixir
def get_user_name(user_idx) do
  FnFlow.run(
    [
      FnFlow.df(fn _state -> AnyModel.get_by_idx(user_idx) end),
      FnFlow.af(fn state ->
        {:ok, user_info} = state.result
        {:ok, user_info.name}
      end
      )
    ]
  )
end

> get_user_name(1)
{:ok, "user_name"}
```