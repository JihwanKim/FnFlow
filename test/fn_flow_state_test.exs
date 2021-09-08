defmodule FnFlowStateTest do
  use ExUnit.Case
  doctest FnFlow.State

  test "state new test" do
    assert FnFlow.State.new() == %{result: {:ok, nil}, execute_count: 0}
  end

  test "state bind test" do
    assert FnFlow.State.bind(%{}, :any, :value) == %{any: :value}
    assert FnFlow.State.bind(%{}, :result, :value) == {:error, :cannot_bind_result}
    assert FnFlow.State.bind(%{}, "any", :value) == {:error, :bind_key_use_only_atom_type}
  end

  test "state result test" do
    assert FnFlow.State.result(FnFlow.State.new()) == {:ok, nil}
    assert FnFlow.State.result(FnFlow.State.new(), {:ok, 1}) == %{result: {:ok, 1}, execute_count: 0}
  end

  test "state okResult test" do
    assert FnFlow.State.okResult(FnFlow.State.new()) == nil
  end

  test "state updateExecuteCount test" do
    assert FnFlow.State.updateExecuteCount(FnFlow.State.new()) == %{result: {:ok, nil}, execute_count: 1}
  end
end
