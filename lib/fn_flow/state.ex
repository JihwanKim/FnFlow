defmodule FnFlow.State do
  @moduledoc false

  def new() do
    %{result: {:ok, nil}, execute_count: 0}
  end

  def result(state) do
    state.result
  end

  def result(state, newResult) do
    %{state | result: newResult}
  end

  def okResult(state) do
    {:ok, v} = state.result
    v
  end

  def bind(_state, :result, _value) do
    {:error, :cannot_bind_result}
  end

  def bind(state, key, value) when is_atom(key) do
    Map.put(state, key, value)
  end

  def bind(_state, _key, _value) do
    {:error, :bind_key_use_only_atom_type}
  end

  def bind(state, key) do
    state[key]
  end

  def updateExecuteCount(state) do
    %{state | execute_count: state.execute_count + 1}
  end
end
