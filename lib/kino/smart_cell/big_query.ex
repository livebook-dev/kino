defmodule Kino.SmartCell.BigQuery do
  @moduledoc false

  # A smart cell used to establish connection to a database.

  use Kino.JS, assets_path: "lib/assets/big_query"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Google BigQuery database connection"

  alias Kino.SmartCell.BigQuery.GothToken

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
      scopes = ["https://www.googleapis.com/auth/cloud-platform"]

      credentials = %{
        "type" => "service_account",
        "project_id" => unquote(attrs["project_id"]),
        "private_key_id" => unquote(attrs["private_key_id"]),
        "private_key" => unquote(private_key(attrs["private_key"])),
        "client_email" => unquote(attrs["client_email"]),
        "client_id" => unquote(attrs["client_id"]),
        "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
        "token_uri" => "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url" => "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url" => unquote(attrs["client_x509_cert_url"])
      }

      dataset = unquote(attrs["dataset"])

      unquote(quoted_var(attrs["variable"])) = BigQuery

      {:ok, goth} =
        Goth.start_link(name: Goth, source: {:service_account, credentials, scopes: scopes})

      {:ok, _finch_pid} = Kino.start_child({Finch, name: BigQuery})
    end
  end

  defp quoted_var(string), do: {String.to_atom(string), [], nil}

  defp private_key(private_key), do: String.replace(private_key, "\\n", "\n")

  defp missing_dep do
    unless ensure_loaded?() do
      """
      {:finch, "~> 0.11.0"},
      {:goth, "~> 1.3.0-rc.3"},
      {:hackney, "~> 1.17"}
      """
    end
  end

  defp ensure_loaded? do
    Code.ensure_loaded?(Finch) and
      Code.ensure_loaded?(Goth.Token) and
      Code.ensure_loaded?(:hackney)
  end
end
