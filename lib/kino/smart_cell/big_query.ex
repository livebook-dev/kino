defmodule Kino.SmartCell.BigQuery do
  @moduledoc false

  # A smart cell used to establish connection to a database.

  use Kino.JS, assets_path: "lib/assets/big_query"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Google BigQuery database connection"

  alias Kino.SmartCell.BigQuery.Connection

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "variable" => Kino.SmartCell.prefixed_var_name("conn", attrs["variable"]),
      "project_id" => attrs["project_id"] || "",
      "dataset" => attrs["dataset"] || "",
      "private_key_id" => attrs["private_key_id"] || "",
      "private_key" => attrs["private_key"] || "",
      "client_email" => attrs["client_email"] || "",
      "client_id" => attrs["client_id"] || "",
      "client_x509_cert_url" => attrs["client_x509_cert_url"] || ""
    }

    {:ok, assign(ctx, fields: fields, missing_dep: missing_dep())}
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

    ctx =
      if missing_dep() == ctx.assigns.missing_dep do
        ctx
      else
        broadcast_event(ctx, "missing_dep", %{"dep" => missing_dep()})
        assign(ctx, missing_dep: missing_dep())
      end

    broadcast_event(ctx, "update", %{"fields" => updated_fields})

    {:noreply, ctx}
  end

  defp to_updates(fields, "variable", value) do
    if Kino.Utils.Code.valid_variable_name?(value) do
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
    |> Kino.Utils.Code.quoted_to_string()
  end

  defp to_quoted(attrs) do
    quote do
      alias unquote(Connection), as: BigQuery

      opts = [
        project_id: unquote(attrs["project_id"]),
        dataset: unquote(attrs["dataset"]),
        service_account: unquote(attrs["service_account"]),
        private_key_id: unquote(attrs["private_key_id"]),
        private_key: unquote(attrs["private_key"]),
        client_email: unquote(attrs["client_email"]),
        client_id: unquote(attrs["client_id"]),
        client_x509_cert_url: unquote(attrs["client_x509_cert_url"])
      ]

      {:ok, _pid} = Kino.start_child({BigQuery, opts})
    end
  end

  defp missing_dep do
    unless ensure_loaded?() do
      """
      {:google_api_big_query, "~> 0.76.0"},
        {:hackney, "~> 1.17"},
        {:goth, "~> 1.3.0-rc.3"}
      """
    end
  end

  defp ensure_loaded? do
    Code.ensure_loaded?(GoogleApi.BigQuery.V2.Connection) and
      Code.ensure_loaded?(Goth.Token) and
      Code.ensure_loaded?(:hackney)
  end
end
