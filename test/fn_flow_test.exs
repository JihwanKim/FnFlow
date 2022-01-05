defmodule FnFlowTest do
  use ExUnit.Case
  doctest FnFlow

  test "FnFlow.bf" do
    assert match?({:bind, _}, FnFlow.bindFun(fn _state -> {:bind_key, {:ok, 1}} end))
    assert match?({:bind, _}, FnFlow.bf(fn _state -> {:bind_key, {:ok, 1}} end))
  end

  test "FnFlow.bfp" do
    assert match?(
             {:bind_parallel, _, _, _},
             FnFlow.bindFunParallel([fn _state -> {:bind_key, {:ok, 1}} end], fn _state, _endData -> :ok end)
           )
    assert match?(
             {:bind_parallel, _, _, _},
             FnFlow.bfp([fn _state -> {:bind_key, {:ok, 1}} end], fn _state, _endData -> :ok end)
           )
  end

  test "FnFlow.df" do
    assert match?({:do, _}, FnFlow.doFun(fn _state -> {:ok, 1} end))
    assert match?({:do, _}, FnFlow.df(fn _state -> {:ok, 1} end))
  end

  test "FnFlow.dfp" do
    assert match?(
             {:do_parallel, _, _, _},
             FnFlow.doFunParallel([fn _state -> {:ok, 1} end], fn _state, _endData -> :ok end)
           )
    assert match?(
             {:do_parallel, _, _, _},
             FnFlow.dfp([fn _state -> {:ok, 1} end], fn _state, _endData -> :ok end)
           )
  end

  test "FnFlow.af" do
    assert match?({:after, _}, FnFlow.afterFun(fn _state -> {:ok, 1} end))
    assert match?({:after, _}, FnFlow.af(fn _state -> {:ok, 1} end))
  end

  test "FnFlow.afp" do
    assert match?(
             {:after_parallel, _, _, _},
             FnFlow.afterFunParallel([fn _state -> {:ok, 1} end], fn _state, _endData -> :ok end)
           )
    assert match?(
             {:after_parallel, _, _, _},
             FnFlow.afp([fn _state -> {:ok, 1} end], fn _state, _endData -> :ok end)
           )
  end

  test "FnFlow.ff" do
    assert match?({:finally, _}, FnFlow.finallyFun(fn _state -> {:ok, 1} end))
    assert match?({:finally, _}, FnFlow.ff(fn _state -> {:ok, 1} end))
  end

  test "FnFlowRun Ok" do
    assert FnFlow.run([]) === {:ok, nil}
  end

  test "FnFlowRun Error" do
    assert FnFlow.run(
             [
               FnFlow.df(fn _state -> {:error, :any_error} end)
             ]
           ) === {:error, :any_error}
  end

  test "FnFlowRun Ok With Bind" do
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:ok, 1} end)
             ]
           ) === {:ok, nil}
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> :ok end)
             ]
           ) === {:ok, nil}
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:bind_key, {:ok, 1}} end)
             ]
           ) === {:ok, nil}
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:bind_key, {:ok, 1}} end),
               FnFlow.df(fn state -> {:ok, state.bind_key} end)
             ]
           ) === {:ok, 1}
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:bind_key, {:ok, 1}} end),
               FnFlow.bf(fn _state -> {:bind_key, {:ok, 2}} end),
               FnFlow.df(fn state -> {:ok, state.bind_key} end)
             ]
           ) === {:ok, 2}
  end

  test "FnFlowRun Error With Bind" do
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:bind_key, {:error, :any_error}} end)
             ]
           ) === {:error, :any_error}
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:bind_key, {:error, :any_error}} end),
               FnFlow.df(fn _state -> {:ok, 1} end)
             ]
           ) === {:error, :any_error}
    assert_raise(
      ArithmeticError,
      fn -> FnFlow.run(
              [
                FnFlow.bf(fn _state -> {:bind_key, {:ok, :a + 1}} end),
                FnFlow.df(fn _state -> {:ok, 1} end)
              ]
            )
      end
    )
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:bind_key, {:error, :any_error}} end),
               FnFlow.bf(fn _state -> {:bind_key, {:ok, :a + 1}} end),
               FnFlow.df(fn _state -> {:ok, 1} end)
             ]
           ) === {:error, :any_error}
    assert_raise(
      ArithmeticError,
      fn -> FnFlow.run(
              [
                FnFlow.bf(fn _state -> {:bind_key, {:ok, :a + 1}} end),
                FnFlow.bf(fn _state -> {:bind_key, {:error, :any_error}} end),
                FnFlow.df(fn _state -> {:ok, 1} end)
              ]
            )
      end
    )
  end

  test "FnFlowRun Ok With DoFun" do
    assert FnFlow.run(
             [
               FnFlow.df(fn _state -> {:ok, 1} end)
             ]
           ) === {:ok, 1}
    assert FnFlow.run(
             [
               FnFlow.df(fn _state -> {:ok, 1} end),
               FnFlow.df(fn _state -> :ok end)
             ]
           ) === {:ok, nil}
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:bind_key, {:ok, 1}} end),
               FnFlow.df(fn state -> {:ok, state.bind_key} end)
             ]
           ) === {:ok, 1}
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:bind_key, {:ok, 1}} end),
               FnFlow.df(fn state -> {:ok, state.bind_key} end),
               FnFlow.df(fn _state -> {:ok, 2} end)
             ]
           ) === {:ok, 2}
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:bind_key, {:ok, 1}} end),
               FnFlow.df(fn state -> {:ok, state.bind_key} end),
               FnFlow.df(fn state -> {:ok, state.bind_key + 1} end)
             ]
           ) === {:ok, 2}
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:bind_key, {:ok, 1}} end),
               FnFlow.df(fn state -> {:ok, state.bind_key} end),
               FnFlow.df(fn state -> state.result end)
             ]
           ) === {:ok, 1}
  end

  test "FnFlowRun Error With Do" do
    assert FnFlow.run(
             [
               FnFlow.df(fn _state -> {:error, :any_error} end)
             ]
           ) === {:error, :any_error}
    assert FnFlow.run(
             [
               FnFlow.df(fn _state -> {:error, :any_error} end),
               FnFlow.df(fn _state -> {:ok, 1} end)
             ]
           ) === {:error, :any_error}

    assert_raise(
      ArithmeticError,
      fn -> FnFlow.run(
              [
                FnFlow.df(fn _state -> {:ok, :a + 1} end),
                FnFlow.df(fn _state -> {:ok, 1} end)
              ]
            )
      end
    )

    assert FnFlow.run(
             [
               FnFlow.df(fn _state -> {:error, :any_error} end),
               FnFlow.df(fn _state -> {:ok, :a + 1} end),
               FnFlow.df(fn _state -> {:ok, 1} end)
             ]
           ) === {:error, :any_error}
    assert_raise(
      ArithmeticError,
      fn -> FnFlow.run(
              [
                FnFlow.df(fn _state -> {:ok, :a + 1} end),
                FnFlow.df(fn _state -> {:error, :any_error} end),
                FnFlow.df(fn _state -> {:ok, 1} end)
              ]
            )
      end
    )
  end

  test "FnFlowRun Ok With AfterFun" do
    assert FnFlow.run(
             [
               FnFlow.df(fn _state -> {:ok, 1} end),
               FnFlow.af(fn _state -> {:ok, 10} end)
             ]
           ) === {:ok, 1}
    assert FnFlow.run(
             [
               FnFlow.df(fn _state -> {:ok, 1} end),
               FnFlow.af(fn state -> {:ok, state.result} end)
             ]
           ) === {:ok, 1}
  end

  test "FnFlowRun Error With AfterFun" do

    assert_raise(
      ArithmeticError,
      fn -> FnFlow.run(
              [
                FnFlow.df(fn _state -> {:ok, 1} end),
                FnFlow.af(fn _state -> {:ok, :a + 1} end)
              ]
            )
      end
    )
    assert FnFlow.run(
             [
               FnFlow.df(fn _state -> {:ok, 1} end),
               FnFlow.af(fn _state -> {:error, :any_error} end)
             ]
           ) === {:error, :any_error}
  end

  test "FnFlowRun With FinallyFun" do
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:bind_key, {:ok, 1}} end),
               FnFlow.ff(
                 fn state ->
                   state.result
                 end
               )
             ]
           ) === {:ok, nil}
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:bind_key, {:ok, 1}} end),
               FnFlow.ff(
                 fn state ->
                   {:ok, state.bind_key}
                 end
               )
             ]
           ) === {:ok, 1}
    assert FnFlow.run(
             [
               FnFlow.bf(fn _state -> {:ok, 1} end),
               FnFlow.ff(
                 fn _state ->
                   {:ok, 123}
                 end
               )
             ]
           ) === {:ok, 123}
    assert FnFlow.run(
             [
               FnFlow.df(fn _state -> {:ok, 1} end),
               FnFlow.ff(
                 fn state ->
                   {:ok, v} = state.result
                   {:ok, v + 1}
                 end
               )
             ]
           ) === {:ok, 2}
    assert FnFlow.run(
             [
               FnFlow.df(fn _state -> {:ok, 1} end),
               FnFlow.ff(fn state -> state.result end)
             ]
           ) === {:ok, 1}
    assert FnFlow.run(
             [
               FnFlow.df(fn _state -> {:ok, 1} end),
               FnFlow.ff(fn _state -> :ok end)
             ]
           ) === {:ok, nil}
  end

  test "FnFlowRun ok2" do
    assert FnFlow.run([]) === {:ok, nil}

    assert FnFlow.run(
             [FnFlow.doFun(fn (_state) -> {:ok, 3} end),]
           ) == {:ok, 3}

    assert FnFlow.run(
             [
               FnFlow.bindFun(fn (_state) -> {:a, {:ok, 1}} end),
               FnFlow.bindFun(fn (_state) -> {:a, {:ok, 3}} end),
               FnFlow.doFun(
                 fn (state) ->
                   {
                     :ok,
                     state
                     |> FnFlow.State.bind(:a)
                   }
                 end
               ),
             ]
           ) == {:ok, 3}

    assert FnFlow.run(
             [
               FnFlow.bindFun(fn (_state) -> {:a, {:ok, 1}} end),
               FnFlow.bindFun(fn (_state) -> {:a, {:ok, 3}} end),
               FnFlow.doFun(
                 fn (state) ->
                   {
                     :ok,
                     state
                     |> FnFlow.State.bind(:a)
                   }
                 end
               ),
               FnFlow.afterFun(
                 fn (_state) ->
                   {:ok, 4}
                 end
               ),
             ]
           ) == {:ok, 3}


    assert FnFlow.run(
             [
               FnFlow.bindFun(fn (_state) -> {:a, {:ok, 3}} end),
               FnFlow.doFun(
                 fn (state) ->
                   {
                     :ok,
                     state.a
                   }
                 end
               ),
               FnFlow.afterFun(
                 fn (state) ->
                   {
                     :ok,
                     state
                     |> FnFlow.State.bind(:a)
                   }
                 end
               ),
               FnFlow.doFun(
                 fn (_state) ->
                   {:ok, 4}
                 end
               ),
             ]
           ) == {:ok, 4}

    assert FnFlow.run(
             [
               FnFlow.bindFun(fn (_state) -> {:a, {:ok, 3}} end),
               FnFlow.doFun(
                 fn (state) ->
                   {
                     :ok,
                     state
                     |> FnFlow.State.bind(:a)
                   }
                 end
               ),
               FnFlow.afterFun(
                 fn (state) ->
                   {
                     :ok,
                     state
                     |> FnFlow.State.bind(:a)
                   }
                 end
               ),
               FnFlow.doFun(
                 fn (state) ->
                   {
                     :ok,
                     (
                       state
                       |> FnFlow.State.okResult) + 1
                   }
                 end
               ),
             ]
           ) == {:ok, 4}
  end
end
