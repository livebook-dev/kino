defmodule Kino.SmartCell.DBConnection do
  @moduledoc false

  # A smart cell used to establish connection to a database.

  use Kino.JS, assets_path: "lib/assets/db_connection"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Database connection"

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "variable" => attrs["variable"] || "conn",
      "type" => attrs["type"] || "postgres",
      "hostname" => attrs["hostname"] || "",
      "port" => attrs["port"] || 5432,
      "username" => attrs["username"] || "",
      "password" => attrs["password"] || "",
      "database" => attrs["database"] || ""
    }

    {:ok, assign(ctx, fields: fields, missing_dep: missing_dep(fields))}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields,
      missing_dep: ctx.assigns.missing_dep
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    updated_fields = to_updates(ctx.assigns.fields, field, value)
    ctx = update(ctx, :fields, &Map.merge(&1, updated_fields))

    missing_dep = missing_dep(ctx.assigns.fields)

    ctx =
      if missing_dep == ctx.assigns.missing_dep do
        ctx
      else
        broadcast_event(ctx, "missing_dep", %{"dep" => missing_dep})
        assign(ctx, missing_dep: missing_dep)
      end

    broadcast_event(ctx, "update", %{"fields" => updated_fields})

    {:noreply, ctx}
  end

  @default_port_by_type %{"postgres" => 5432, "mysql" => 3306}

  defp to_updates(_fields, "port", "") do
    %{"port" => nil}
  end

  defp to_updates(_fields, "port", value) do
    %{"port" => String.to_integer(value)}
  end

  defp to_updates(_fields, "type", value) do
    %{"type" => value, "port" => @default_port_by_type[value]}
  end

  defp to_updates(fields, "variable", value) do
    if valid_variable_name?(value) do
      %{"variable" => value}
    else
      %{"variable" => fields["variable"]}
    end
  end

  defp to_updates(_fields, field, value), do: %{field => value}

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.fields
  end

  @impl true
  def to_source(attrs) do
    attrs
    |> to_quoted()
    |> Macro.to_string()
    # TODO: remove reformatting on Elixir v1.14 (before v1.13.1
    # Macro.to_string/1 formats with line length of :infinity)
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end

  defp to_quoted(%{"type" => "postgres"} = attrs) do
    to_quoted(quote(do: Postgrex), attrs)
  end

  defp to_quoted(%{"type" => "mysql"} = attrs) do
    to_quoted(quote(do: MyXQL), attrs)
  end

  defp to_quoted(_ctx) do
    quote do
    end
  end

  defp to_quoted(quoted_module, attrs) do
    quote do
      opts = [
        hostname: unquote(attrs["hostname"]),
        port: unquote(attrs["port"]),
        username: unquote(attrs["username"]),
        password: unquote(attrs["password"]),
        database: unquote(attrs["database"])
      ]

      {:ok, unquote(quoted_var(attrs["variable"]))} =
        Kino.start_child({unquote(quoted_module), opts})
    end
  end

  defp quoted_var(string), do: {String.to_atom(string), [], nil}

  defp missing_dep(%{"type" => "postgres"}) do
    unless Code.ensure_loaded?(Postgrex) do
      ~s/{:postgrex, "~> 0.16.1"}/
    end
  end

  defp missing_dep(%{"type" => "mysql"}) do
    unless Code.ensure_loaded?(MyXQL) do
      ~s/{:myxql, "~> 0.6.1"}/
    end
  end

  defp missing_dep(_ctx), do: nil

  defp valid_variable_name?(string) do
    atom = String.to_atom(string)
    macro_classify_atom(atom) == :identifier
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
