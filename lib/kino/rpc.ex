defmodule Kino.RPC do
  @moduledoc """
  Functions for working with remote nodes.
  """

  @relative_file Path.relative_to_cwd(__ENV__.file)

  @doc """
  Evaluates the contents given by `string` on the given `node`.

  Returns the value returned from evaluation.

  The code is analyzed for variable references, they are automatically
  extracted from the caller binding and passed to the evaluation. This
  means that the evaluated string actually has closure semantics.

  The code is parsed and expanded on the remote node. Also, errors
  and exits are captured and propagated to the caller.

  See `Code.eval_string/3` for available `opts`.
  """
  defmacro eval_string(node, string, opts \\ []) do
    string = Macro.expand(string, __CALLER__)

    unless is_binary(string) do
      raise ArgumentError,
            "Kino.RPC.eval_string/3 expects a string literal as the second argument"
    end

    used_var_names = used_var_names(string, __CALLER__)

    binding = for name <- used_var_names, do: {name, Macro.var(name, nil)}

    quote do
      Kino.RPC.__remote_eval_string__(
        unquote(node),
        unquote(string),
        unquote(binding),
        unquote(opts)
      )
    end
  end

  defp used_var_names(string, env) do
    # TODO: only keep :emit_warnings once we require Elixir v1.16+
    case Code.string_to_quoted(string, emit_warnings: false, warn_on_unnecessary_quotes: false) do
      {:ok, ast} ->
        # This is a simple heuristic, we traverse the unexpanded AST
        # and look for any variable node. This means we may have false
        # positives if there are macros, but in our use case this is
        # acceptable. We may also have false negatives in very specific
        # edge cases, such as calling `binding()`, but these are even
        # more unlikely.

        names = Map.new(Macro.Env.vars(env))

        ast
        |> Macro.prewalk(MapSet.new(), fn
          {name, _, nil} = node, acc when is_map_key(names, name) ->
            {node, MapSet.put(acc, name)}

          node, acc ->
            {node, acc}
        end)
        |> elem(1)

      {:error, _} ->
        []
    end
  end

  @doc false
  def __remote_eval_string__(node, string, binding, opts) do
    opts = Keyword.validate!(opts, [:file, :line])

    # We do a nested evaluation to catch errors and capture diagnostics.
    # Also, note that `eval_string` returns both result and binding,
    # so in order to minimize the data sent between nodes, we bind the
    # result and diagnostics to `output` and we rebind `input` to `nil`.

    line = __ENV__.line + 4

    eval_string =
      """
      output =
        Code.with_diagnostics([log: false], fn ->
          {string, binding, opts} = input

          try do
            quoted = Code.string_to_quoted!(string, opts)
            {value, _binding} = Code.eval_quoted(quoted, binding, opts)
            {:ok, value}
          catch
            kind, error ->
              {:error, kind, error, __STACKTRACE__}
          end
        end)

      input = nil
      """

    {nil, binding} =
      :erpc.call(node, Code, :eval_string, [
        eval_string,
        [input: {string, binding, opts}],
        [file: @relative_file, line: line]
      ])

    {result, diagnostics} = binding[:output]

    for diagnostic <- diagnostics do
      Code.print_diagnostic(diagnostic)
    end

    case result do
      {:ok, value} ->
        value

      {:error, :error, error, stacktrace} ->
        error = Exception.normalize(:error, error, stacktrace)
        reraise error, stacktrace

      {:error, :throw, value, _stacktrace} ->
        throw(value)

      {:error, :exit, reason, _stacktrace} ->
        exit(reason)
    end
  end
end
