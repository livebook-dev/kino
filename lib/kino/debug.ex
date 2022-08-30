defmodule Kino.Debug do
  @moduledoc false

  @registry Kino.Debug.Registry

  @doc """
  Custom backend for `Kernel.dbg/2`.

  The custom backend provides a more interactive user interface for
  `Kernel.dbg/2` calls in certain cases, such as call pipelines. It
  falls back to the default backend otherwise.
  """
  @spec dbg(Macro.t(), Macro.t(), Macro.Env.t()) :: Macro.t()
  def dbg(ast, _options, %Macro.Env{} = env) do
    dbg_id = System.unique_integer()

    case ast do
      {:|>, _meta, _args} ->
        dbg_pipeline_ast(ast, dbg_id, env)

      _ ->
        dbg_default_ast(ast, dbg_id, env)
    end
  end

  defp dbg_default_ast(ast, dbg_id, env) do
    source = Macro.to_string(ast)

    quote do
      result = unquote(ast)

      if pid = unquote(__MODULE__).lookup_dbg_handler(unquote(dbg_id)) do
        send(pid, :dbg_call)
      else
        unquote(__MODULE__).render_dbg_default(
          unquote(source),
          result,
          unquote(dbg_id),
          unquote(env.file),
          unquote(env.line)
        )
      end

      result
    end
  end

  defp dbg_pipeline_ast(ast, dbg_id, env) do
    [head_ast | rest_asts] = asts = for {ast, 0} <- Macro.unpipe(ast), do: ast

    head_source = Macro.to_string(head_ast)
    rest_sources = for ast <- rest_asts, do: "|> " <> Macro.to_string(ast)
    sources = [head_source | rest_sources]

    [head_var | rest_vars] = vars = Macro.generate_arguments(length(asts), __MODULE__)

    assignments = quote do: unquote(head_var) = unquote(head_ast)

    {assignments, _} =
      rest_vars
      |> Enum.zip(rest_asts)
      |> Enum.reduce({assignments, head_var}, fn {var, node}, {assignments, prev_var} ->
        assignments =
          quote do
            unquote(assignments)
            unquote(var) = unquote(Macro.pipe(prev_var, node, 0))
          end

        {assignments, var}
      end)

    funs =
      for ast <- rest_asts do
        arg = Macro.var(:arg, __MODULE__)
        expr = Macro.pipe(arg, ast, 0)

        quote do
          fn unquote(arg) -> unquote(expr) end
        end
      end

    quote do
      unquote(assignments)

      if pid = unquote(__MODULE__).lookup_dbg_handler(unquote(dbg_id)) do
        send(pid, :dbg_call)
      else
        # We want to send a list of functions to the kino process,
        # however that would copy relevant binding entries for each
        # function individually. To avoid that, we wrap the list in
        # another function, so the binding is copied only once and
        # we unpack the list in the kino process
        wrapped_funs = fn -> unquote(funs) end

        unquote(__MODULE__).render_dbg_pipeline(
          unquote(sources),
          unquote(vars),
          wrapped_funs,
          unquote(dbg_id),
          unquote(env.file),
          unquote(env.line)
        )
      end

      unquote(List.last(vars))
    end
  end

  @doc false
  def render_dbg_default(source, result, dbg_id, dbg_file, dbg_line) do
    evaluation_file = Kino.Bridge.get_evaluation_file()
    same_file? = evaluation_file == dbg_file

    Kino.Debug.Default.new(source, result, dbg_id, same_file?, dbg_line)
    |> Kino.render()
  end

  @doc false
  def render_dbg_pipeline(sources, results, wrapped_funs, dbg_id, dbg_file, dbg_line) do
    evaluation_file = Kino.Bridge.get_evaluation_file()
    same_file? = evaluation_file == dbg_file

    Kino.Debug.Pipeline.new(sources, results, wrapped_funs, dbg_id, same_file?, dbg_line)
    |> Kino.render()
  end

  @doc """
  Registers caller as the process handling the given dbg call.
  """
  @spec register_dbg_handler!(integer()) :: :ok
  def register_dbg_handler!(dbg_id) do
    {:ok, _} = Registry.register(@registry, dbg_id, nil)
    :ok
  end

  @doc """
  Looks up a process handling the given dbg call.
  """
  @spec lookup_dbg_handler(integer()) :: pid() | nil
  def lookup_dbg_handler(dbg_id) do
    case Registry.lookup(@registry, dbg_id) do
      [] -> nil
      [{pid, _}] -> pid
    end
  end
end
