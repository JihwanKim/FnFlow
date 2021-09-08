defmodule FnFlow do
  @moduledoc """
  Documentation for `FnFlow`.

  FnFlow is side effect process library.
  this idea by https://github.com/zntus and https://github.com/JihwanKim

  this library error catch at bind/do/after
  this library not catch finally. if crash in finally function, throw item.
  """

  @doc """
  FnFlow bind data function
  """
  @spec bindFun(bindingFunction :: fun) :: {:bind, fun}
  def bindFun (bindingFunction) do
    {:bind, bindingFunction}
  end

  @doc """
  FnFlow.bindFun/1 shortCut
  """
  @spec bf(bindingFunction :: fun) :: {:bind, fun}
  def bf(bindingFunction) do
    bindFun (bindingFunction)
  end

  @doc """
  FnFlow bind data function

  ## Example
    bindFunParallel(
      [
        fn(_state)->
          {:ok, 1}
        end
      ],
      fn (state, onEndData)->
        {:bind_key, {:ok, onEndData}}
      end,
      [pool: 10]
    )
  """
  @spec bindFunParallel(bindingFunction :: list(fun), onEndFunction :: fun) :: {:bind_parallel, list(fun), fun}
  def bindFunParallel(bindingFunctions, onEndFunction, opts \\ []) do
    {:bind_parallel, bindingFunctions, onEndFunction, opts}
  end

  @doc """
  FnFlow.bindFunParallel/2 shortCut
  FnFlow.bindFunParallel/3 shortCut
  """
  @spec bfp(bindingFunction :: list(fun), onEndFunction :: fun) :: {:bind_parallel, list(fun), fun}
  def bfp(bindingFunctions, onEndFunction, opts \\ []) do
    bindFunParallel(bindingFunctions, onEndFunction, opts)
  end

  @doc """
  FnFlow do function
  data bind only result
  """
  @spec doFun(doFunction :: fun) :: {:do, fun}
  def doFun (doFunction) do
    {:do, doFunction}
  end

  @doc """
  FnFlow.doFun/1 shortCut
  """
  @spec df(doFunction :: fun) :: {:do, fun}
  def df (doFunction) do
    doFun (doFunction)
  end

  @doc """
  FnFlow bind data function

  ## Example
    doFunParallel(
      [
        fn(_state)->
          {:ok, 1}
        end
      ],
      fn (state, onEndData)->
        {:ok, onEndData}
      end,
      [pool: 10]
    )
  """
  @spec doFunParallel(doFunctions :: list(fun), onEndFunction :: fun) :: {:do_parallel, list(fun), fun}
  def doFunParallel(doFunctions, onEndFunction, opts \\ [pool: :infinity]) do
    {:do_parallel, doFunctions, onEndFunction, opts}
  end

  @doc """
  FnFlow.doFunParallel/2 shortCut
  FnFlow.doFunParallel/3 shortCut
  """
  @spec dfp(doFunctions :: list(fun), onEndFunction :: fun) :: {:do_parallel, list(fun), fun}
  def dfp(doFunctions, onEndFunction, opts \\ [pool: :infinity]) do
    doFunParallel(doFunctions, onEndFunction, opts)
  end

  @doc """
  FnFlow after function
  data not bind anything. but result is error, run function will return error
  """
  @spec afterFun(afterFunction :: fun) :: {:after, fun}
  def afterFun (afterFunction) do
    {:after, afterFunction}
  end

  @doc """
  FnFlow.afterFun/1 shortCut
  """
  @spec af(afterFunction :: fun) :: {:after, fun}
  def af (afterFunction) do
    afterFun (afterFunction)
  end

  @doc """
  FnFlow after function
  data not bind anything. but result is error, run function will return error

  ## Example
    afterFunParallel(
      [
        fn(_state)->
          {:ok, 1}
        end
      ],
      fn (state, onEndData)->
        :ok
      end,
      [pool: 10]
    )

    afterFunParallel(
      [
        fn(_state)->
          {:ok, 1}
        end
      ]
    )
  """
  @spec afterFunParallel(doFunctions :: list(fun), onEndFun :: fun) :: {:after_parallel, list(fun), fun}
  def afterFunParallel(doFunctions, onEndFun \\ fn (_, _) -> :ok end, opts \\ []) do
    {:after_parallel, doFunctions, onEndFun, opts}
  end

  @doc """
  FnFlow.afterFunParallel/2 shortCut
  FnFlow.afterFunParallel/3 shortCut
  """
  @spec afp(doFunctions :: list(fun), onEndFun :: fun) :: {:after_parallel, list(fun), fun}
  def afp(doFunctions, onEndFun \\ fn (_, _) -> :ok end, opts \\ []) do
    afterFunParallel(doFunctions, onEndFun, opts)
  end

  @doc """
  FnFlow finally function
  this function always running function.
  can update state.result
  """
  @spec finallyFun(finallyFunction :: fun) :: {:finally, fun}
  def finallyFun (finallyFunction) do
    {:finally, finallyFunction}
  end

  @doc """
  FnFlow.finallyFun/1 shortCut
  """
  @spec ff(finallyFunction :: fun) :: {:finally, fun}
  def ff (finallyFunction) do
    finallyFun (finallyFunction)
  end

  @doc """
  run ex flow logic

          FnFlow.bind(
            fn(state)->
              {:ok, {:anyKey, :anyValue}}
            end
          )

  ## Example

    iex> FnFlow.run([])
    {:ok, nil}
  """
  def run(functions) do
    state = loop(FnFlow.State.new(), functions)
    state.result
  end

  #################################
  ####### internal Function #######
  #################################

  defp loop(state, []) do
    state
  end
  defp loop(state, [{:bind, currentFunction} | functions]) do
    result =
      try do
        currentFunction.(state)
      catch
        _, err -> err
      end

    case result do
      :ok ->
        state
        |> loop(functions)
      {:ok, _} ->
        state
        |> loop(functions)
      {bindingKey, :ok} ->
        state
        |> FnFlow.State.bind(bindingKey, nil)
        |> loop(functions)
      {bindingKey, {:ok, value}} ->
        state
        |> FnFlow.State.bind(bindingKey, value)
        |> loop(functions)
      {_, {:error, _} = err} ->
        state
        |> FnFlow.State.result(err)
        |> do_only_finally(functions)
      {:error, _} = err ->
        state
        |> FnFlow.State.result(err)
        |> do_only_finally(functions)
      err ->
        state
        |> FnFlow.State.result({:error, err})
        |> do_only_finally(functions)
    end
  end
  defp loop(state, [{:bind_parallel, currentFunctions, onEndFunction, opts} | functions]) do
    result =
      try do
        rs =
          state
          |> parallel_worker(currentFunctions, opts)
        state
        |> onEndFunction.(rs)
      catch
        :error, err ->
          err
      end

    case result do
      :ok ->
        state
        |> loop(functions)
      {:ok, _} ->
        state
        |> loop(functions)
      {bindingKey, :ok} ->
        state
        |> FnFlow.State.bind(bindingKey, nil)
        |> loop(functions)
      {bindingKey, {:ok, value}} ->
        state
        |> FnFlow.State.bind(bindingKey, value)
        |> loop(functions)
      {_, {:error, _} = err} ->
        state
        |> FnFlow.State.result(err)
        |> do_only_finally(functions)
      {:error, _} = err ->
        state
        |> FnFlow.State.result(err)
        |> do_only_finally(functions)
      err ->
        state
        |> FnFlow.State.result({:error, err})
        |> do_only_finally(functions)
    end
  end
  defp loop(state, [{:do, currentFunction} | functions]) do
    result =
      try do
        currentFunction.(state)
      catch
        :error, err -> err
      end

    case result do
      :ok ->
        state
        |> FnFlow.State.result({:ok, nil})
        |> loop(functions)
      {:ok, _} ->
        state
        |> FnFlow.State.result(result)
        |> loop(functions)
      {:error, _} = err ->
        state
        |> FnFlow.State.result(err)
        |> do_only_finally(functions)
      err when is_atom(err) ->
        state
        |> FnFlow.State.result({:error, err})
        |> do_only_finally(functions)
    end
  end
  defp loop(state, [{:do_parallel, currentFunctions, onEndFunction, opts} | functions]) do
    result =
      try do
        rs =
          state
          |> parallel_worker(currentFunctions, opts)
        state
        |> onEndFunction.(rs)
      catch
        :error, err ->
          err
      end

    case result do
      :ok ->
        state
        |> FnFlow.State.result({:ok, nil})
        |> loop(functions)
      {:ok, _} ->
        state
        |> FnFlow.State.result(result)
        |> loop(functions)
      {:error, _} = err ->
        state
        |> FnFlow.State.result(err)
        |> do_only_finally(functions)
      err when is_atom(err) ->
        state
        |> FnFlow.State.result({:error, err})
        |> do_only_finally(functions)
    end
  end
  defp loop(state, [{:after, currentFunction} | functions]) do
    result =
      try do
        currentFunction.(state)
      catch
        :error, err -> err
      end

    case result do
      :ok ->
        state
        |> loop(functions)
      {:ok, _} ->
        state
        |> loop(functions)
      {:error, _} = err ->
        state
        |> FnFlow.State.result(err)
        |> do_only_finally(functions)
      err when is_atom(err) ->
        state
        |> FnFlow.State.result({:error, err})
        |> do_only_finally(functions)
    end
  end
  defp loop(state, [{:after_parallel, currentFunctions, onEndFunction, opts} | functions]) do
    result =
      try do
        rs =
          state
          |> parallel_worker(currentFunctions, opts)
        state
        |> onEndFunction.(rs)
      catch
        :error, err ->
          err
      end

    case result do
      :ok ->
        state
        |> loop(functions)
      {:ok, _} ->
        state
        |> loop(functions)
      {:error, _} = err ->
        state
        |> FnFlow.State.result(err)
        |> do_only_finally(functions)
      err when is_atom(err) ->
        state
        |> FnFlow.State.result({:error, err})
        |> do_only_finally(functions)
    end
  end
  defp loop(state, [{:finally, currentFunction} | functions]) do
    result =
      try do
        state
        |> currentFunction.()
      catch
        :error, err -> err
      end

    case result do
      :ok ->
        state
        |> FnFlow.State.result({:ok, nil})
        |> loop(functions)
      {:ok, _} ->
        state
        |> FnFlow.State.result(result)
        |> loop(functions)
      {:error, _} = err ->
        state
        |> FnFlow.State.result(err)
        |> do_only_finally(functions)
      err when is_atom(err) ->
        state
        |> FnFlow.State.result({:error, err})
        |> do_only_finally(functions)
    end
  end

  defp do_only_finally(state, []) do
    state
  end
  defp do_only_finally(state, [{:finally, function} | functions]) do
    state
    |> loop([{:finally, function}])
    |> do_only_finally(functions)
  end
  defp do_only_finally(state, [_ | functions]) do
    state
    |> do_only_finally(functions)
  end

  defp parallel_worker(state, [firstFunction | _] = functions, opts)
       when is_list(functions) and is_function(firstFunction) do
    parentPid = self()

    idxAndRunFuns =
      List.foldl(
        functions,
        [],
        fn (function, acc) ->
          idx = length(acc)
          runFun =
            fn ->
              Process.spawn(
                fn ->
                  rs =
                    try do
                      state
                      |> function.()
                    catch
                      :error, err ->
                        err
                    end
                  send(parentPid, {self(), rs})
                end,
                [:link]
              )
            end
          [{idx, runFun} | acc]
        end
      )

    {idxAndRunFuns, pidAndFunctionMap} =
      List.foldr(
        idxAndRunFuns,
        {[], %{}},
        fn ({idx, function}, {restAcc, mapAcc}) ->
          case  Keyword.get(opts, :pool, :infinity) do
            :infinity ->
              pid = function.()
              {restAcc, Map.put(mapAcc, pid, {idx, function})}
            requirePoolSize when idx < requirePoolSize ->
              pid = function.()
              {restAcc, Map.put(mapAcc, pid, {idx, function})}
            _ ->
              {[{idx, function} | restAcc], mapAcc}
          end
        end
      )
    parallel_worker_internal(idxAndRunFuns, pidAndFunctionMap, [], opts)
  end

  defp parallel_worker_internal([], workingItemMap, rs, _opts) when map_size(workingItemMap) == 0 do
    Enum.sort_by(rs, fn {idx, _} -> idx  end)
    |> Enum.map(fn ({_, v}) -> v end)
  end

  defp parallel_worker_internal(idxAndRunFuns, workingItemMap, rs, opts) do
    receive do
      {workerPid, workerResult} ->
        {idx, _workingFun} = workingItemMap[workerPid]
        restItemMap = Map.delete(workingItemMap, workerPid)
        {idxAndRunFuns, restItemMap} =
          case idxAndRunFuns do
            [] -> {[], restItemMap}
            [{nextIdx, newDoFunction} | rest] ->
              pid = newDoFunction.()
              {rest, Map.put(restItemMap, pid, {nextIdx, newDoFunction})}
          end
        parallel_worker_internal(idxAndRunFuns, restItemMap, [{idx, workerResult} | rs], opts)
    end
  end

  def doTest() do
    FnFlow.run(
      [
        FnFlow.bfp(
          [
            fn (state) -> {:ok, 1} end,
            fn (state) -> {:ok, 1} end,
            fn (state) -> {:ok, 1} end
          ],
          fn (state, onEndData) -> {:bind_key, {:ok, onEndData}} end,
          [pool: :infinity]
        ),
        FnFlow.dfp(
          [
            fn (state) -> {:ok, 1} end,
            fn (state) -> {:ok, 2} end,
            fn (state) -> {:ok, 3} end
          ],
          fn (state, onEndData) ->
            {
              :ok,
              onEndData
            }
          end
        ),
        FnFlow.afp(
          [
            fn (state) ->
              {:ok, 1}
            end,
            fn (state) ->
              {:ok, 2}
            end,
            fn (state) ->
              {:ok, 3}
            end
          ]
        )
      ]
    )
  end
end
