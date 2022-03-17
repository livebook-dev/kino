defmodule Kino.Utils.Code do
  @moduledoc false

  @doc """
  Checks if the given string is a valid Elixir variable name.
  """
  @spec valid_variable_name?(String.t()) :: boolean()
  def valid_variable_name?(string) do
    atom = String.to_atom(string)
    macro_classify_atom(atom) == :identifier
  end

  @doc """
  Converts the given AST to formatted code string.
  """
  @spec quoted_to_string(Macro.t()) :: String.t()
  def quoted_to_string(quoted) do
    quoted
    |> Code.quoted_to_algebra()
    |> Inspect.Algebra.format(90)
    |> IO.iodata_to_binary()
  end

  # ---

  # TODO: use Macro.classify_atom/1 on Elixir 1.14

  def macro_classify_atom(atom) do
    case macro_inner_classify(atom) do
      :alias -> :alias
      :identifier -> :identifier
      type when type in [:unquoted_operator, :not_callable] -> :unquoted
      _ -> :quoted
    end
  end

  defp macro_inner_classify(atom) when is_atom(atom) do
    cond do
      atom in [:%, :%{}, :{}, :<<>>, :..., :.., :., :"..//", :->] ->
        :not_callable

      atom in [:"::"] ->
        :quoted_operator

      Macro.operator?(atom, 1) or Macro.operator?(atom, 2) ->
        :unquoted_operator

      true ->
        charlist = Atom.to_charlist(atom)

        if macro_valid_alias?(charlist) do
          :alias
        else
          case :elixir_config.identifier_tokenizer().tokenize(charlist) do
            {kind, _acc, [], _, _, special} ->
              if kind == :identifier and not :lists.member(?@, special) do
                :identifier
              else
                :not_callable
              end

            _ ->
              :other
          end
        end
    end
  end

  defp macro_valid_alias?('Elixir' ++ rest), do: macro_valid_alias_piece?(rest)
  defp macro_valid_alias?(_other), do: false

  defp macro_valid_alias_piece?([?., char | rest]) when char >= ?A and char <= ?Z,
    do: macro_valid_alias_piece?(macro_trim_leading_while_valid_identifier(rest))

  defp macro_valid_alias_piece?([]), do: true
  defp macro_valid_alias_piece?(_other), do: false

  defp macro_trim_leading_while_valid_identifier([char | rest])
       when char >= ?a and char <= ?z
       when char >= ?A and char <= ?Z
       when char >= ?0 and char <= ?9
       when char == ?_ do
    macro_trim_leading_while_valid_identifier(rest)
  end

  defp macro_trim_leading_while_valid_identifier(other) do
    other
  end
end
