defmodule Kino.SmartCell.DBConnection do
  @moduledoc false

  # A smart cell used to establish connection to a database.

  use Kino.JS, assets_path: "lib/assets/db_connection"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Database connection"

  @default_port_by_type %{"postgres" => 5432, "mysql" => 3306}

  @impl true
  def init(attrs, ctx) do
    default_type = default_db_type()
    default_port = @default_port_by_type[default_type]

    fields = %{
      "variable" => Kino.SmartCell.prefixed_var_name("conn", attrs["variable"]),
      "type" => attrs["type"] || default_type,
      "hostname" => attrs["hostname"] || "",
      "port" => attrs["port"] || default_port,
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

  defp to_updates(_fields, "port", value) do
    port =
      case Integer.parse(value) do
        {n, ""} -> n
        _ -> nil
      end

    %{"port" => port}
  end

  defp to_updates(_fields, "type", value) do
    %{"type" => value, "port" => @default_port_by_type[value]}
  end

  defp to_updates(fields, "variable", value) do
    if Kino.SmartCell.valid_variable_name?(value) do
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
    attrs |> to_quoted() |> Kino.SmartCell.quoted_to_string()
  end

  defp to_quoted(%{"type" => "postgres"} = attrs) do
    to_quoted(attrs, quote(do: Postgrex))
  end

  defp to_quoted(%{"type" => "mysql"} = attrs) do
    to_quoted(attrs, quote(do: MyXQL))
  end

  defp to_quoted(_ctx) do
    quote do
    end
  end

  defp to_quoted(attrs, quoted_module) do
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

  defp default_db_type() do
    cond do
      Code.ensure_loaded?(Postgrex) -> "postgres"
      Code.ensure_loaded?(MyXQL) -> "mysql"
      true -> "postgres"
    end
  end

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
end
