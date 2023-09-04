defmodule Kino.RemoteCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/remote_cell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Remote cell"

  @default_code ":ok"

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "assign_to" => attrs["assign_to"],
      "cookie" => attrs["cookie"],
      "node" => attrs["node"]
    }

    ctx = assign(ctx, fields: fields)

    {:ok, ctx, editor: [attribute: "code", language: "elixir", default_source: @default_code]}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{fields: ctx.assigns.fields}
    {:ok, payload, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    ctx = update(ctx, :fields, &Map.put(&1, field, value))
    broadcast_event(ctx, "update_field", %{"fields" => %{field => value}})

    {:noreply, ctx}
  end

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.fields
  end

  @impl true
  def to_source(attrs) do
    attrs |> to_quoted() |> Kino.SmartCell.quoted_to_string()
  end

  defp to_quoted(_ctx) do
    quote do
    end
  end
end
