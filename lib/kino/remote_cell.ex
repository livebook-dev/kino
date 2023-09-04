defmodule Kino.RemoteCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/remote_cell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Remote cell"

  @default_code ":ok"

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "assign_to" => attrs["assign_to"] || "",
      "cookie" => attrs["cookie"] || "",
      "node" => attrs["node"] || ""
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
  def to_source(%{"node" => ""}), do: ""
  def to_source(%{"cookie" => ""}), do: ""
  def to_source(%{"code" => ""}), do: ""

  def to_source(%{"code" => code} = attrs) do
    code = Code.string_to_quoted(code)
    to_quoted(attrs, code)
  end

  defp to_quoted(%{"node" => node, "cookie" => cookie, "assign_to" => var}, {:ok, code}) do
    var = if Kino.SmartCell.valid_variable_name?(var), do: var
    call = build_call(code) |> build_var(var)

    quote do
      node = unquote(String.to_atom(node))
      cookie = unquote(String.to_atom(cookie))
      Node.set_cookie(node, cookie)
      unquote(call)
    end
    |> Kino.SmartCell.quoted_to_string()
  end

  defp to_quoted(%{"code" => code}, {:error, _reason}) do
    "# Invalid code for RPC, reproducing the error below\n" <>
      Kino.SmartCell.quoted_to_string(
        quote do
          Code.string_to_quoted!(unquote(code))
        end
      )
  end

  defp build_call(code) do
    quote do
      :erpc.call(node, fn -> unquote(code) end)
    end
  end

  defp build_var(call, nil), do: call

  defp build_var(call, var) do
    quote do
      unquote({String.to_atom(var), [], nil}) = unquote(call)
    end
  end
end
