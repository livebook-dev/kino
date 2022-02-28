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
  def handle_event("update", %{"field" => field, "value" => value}, ctx) do
    updated_fields = to_updates(field, value)
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

  defp to_updates("port", ""), do: %{"port" => nil}
  defp to_updates("port", value), do: %{"port" => String.to_integer(value)}
  defp to_updates("type", value), do: %{"type" => value, "port" => @default_port_by_type[value]}
  defp to_updates(field, value), do: %{field => value}

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.fields
  end

  @impl true
  def to_source(attrs) do
    to_quoted(attrs)
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end

  defp to_quoted(%{"type" => "postgres"} = attrs) do
    quote do
      {:ok, unquote({String.to_atom(attrs["variable"]), [], nil})} =
        Postgrex.start_link(
          hostname: unquote(attrs["hostname"]),
          port: unquote(attrs["port"]),
          username: unquote(attrs["username"]),
          password: unquote(attrs["password"]),
          database: unquote(attrs["database"])
        )
    end
  end

  defp to_quoted(%{"type" => "mysql"} = attrs) do
    quote do
      {:ok, unquote({String.to_atom(attrs["variable"]), [], nil})} =
        MyXQL.start_link(
          hostname: unquote(attrs["hostname"]),
          port: unquote(attrs["port"]),
          username: unquote(attrs["username"]),
          password: unquote(attrs["password"]),
          database: unquote(attrs["database"])
        )
    end
  end

  defp to_quoted(_ctx) do
    quote do: []
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
