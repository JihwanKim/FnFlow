# FnFlow

Elixir function compose library.

### TODO List

- [ ] add debug mode
- [ ] add state on error point

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `fnflow` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fnflow, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can be found
at [https://hexdocs.pm/fnflow](https://hexdocs.pm/fnflow).

## Example

sign up sample

```elixir
def validate_id(account_id) do
  case String.length(account_id) > 4 and String.length(account_id) < 30 do
    true -> {:ok, account_id}
    false -> {:error, :account_id_length_short_or_long}
  end
end

def validate_password(account_password) do
  case String.length(account_password) > 8 and String.length(account_password) < 30 do
    true -> {:ok, account_password}
    false -> {:error, :account_password_length_short_or_long}
  end
end

def password_encrypt(account_password) do
  {:ok, "any_encrypt"}
end

def validate_name(name) do
  case String.length(name) > 2 and String.length(name) < 12 do
    true -> {:ok, name}
    false -> {:error, :name_length_short_or_long}
  end
end

def sign_up(account_id, account_password, name) do
  FnFlow.run(
    [
      FnFlow.df(fn _state -> validate_id(account_id) end),
      FnFlow.df(fn _state -> validate_password(account_password) end),
      FnFlow.df(fn _state -> validate_name(name) end),
      FnFlow.bf(fn _state -> {:password, password_encrypt(account_password)} end),
      FnFlow.df(fn state -> Model.User.insert(account_id, state.password, name) end)
    ]
  )
end


iex > sign_up("hello", "password1234", "user_name")
# any success result

iex > sign_up("hel", "password1234", "user_name")
{:error, :account_id_length_short_or_long}

iex > sign_up("hello", "passwo", "user_name")
{:error, :account_password_length_short_or_long}

iex > sign_up("hello", "password1234", "u")
{:error, :name_length_short_or_long}
```