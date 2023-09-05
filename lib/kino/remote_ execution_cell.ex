defmodule Kino.RemoteExecutionCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/remote_execution_cell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Remote execution"

  @default_code ":ok"

  @impl true
  def init(attrs, ctx) do
    use_cookie_secret =
      if Map.has_key?(attrs, "use_cookie_secret"), do: attrs["use_cookie_secret"], else: true

    fields = %{
      "assign_to" => attrs["assign_to"] || "",
      "node" => attrs["node"] || "",
      "cookie" => attrs["cookie"],
      "use_cookie_secret" => use_cookie_secret,
      "cookie_secret" => attrs["cookie_secret"]
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
  def to_source(%{"code" => ""}), do: ""
  def to_source(%{"node" => ""}), do: ""
  def to_source(%{"use_cookie_secret" => false, "cookie" => ""}), do: ""
  def to_source(%{"use_cookie_secret" => true, "cookie_secret" => ""}), do: ""

  def to_source(%{"code" => code} = attrs) do
    code = Code.string_to_quoted(code)
    to_source(attrs, code)
  end

  defp to_source(%{"node" => node, "assign_to" => var} = attrs, {:ok, code}) do
    var = if Kino.SmartCell.valid_variable_name?(var), do: var
    call = build_call(code) |> build_var(var)
    cookie = build_set_cookie(attrs)

    quote do
      node = unquote(String.to_atom(node))
      Node.set_cookie(node, unquote(cookie))
      unquote(call)
    end
    |> Kino.SmartCell.quoted_to_string()
  end

  defp to_source(%{"code" => code}, {:error, _reason}) do
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

  defp build_set_cookie(%{"use_cookie_secret" => true, "cookie_secret" => secret}) do
    quote do
      String.to_atom(System.fetch_env!(unquote("LB_#{secret}")))
    end
  end

  defp build_set_cookie(%{"cookie" => cookie}), do: String.to_atom(cookie)
end
