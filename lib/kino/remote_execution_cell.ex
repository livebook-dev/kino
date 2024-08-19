defmodule Kino.RemoteExecutionCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/remote_execution_cell/build"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Remote execution"

  alias Kino.AttributeStore

  @default_code ":ok"
  @global_key __MODULE__
  @global_attrs ["node", "cookie", "cookie_secret", "node_secret"]
  @distribution_attrs [
    "node",
    "use_node_secret",
    "node_secret",
    "cookie",
    "use_cookie_secret",
    "cookie_secret"
  ]

  @impl true
  def init(attrs, ctx) do
    {shared_cookie, shared_cookie_secret} =
      AttributeStore.get_attribute({@global_key, :cookie}, {nil, nil})

    {shared_node, shared_node_secret} =
      AttributeStore.get_attribute({@global_key, :node}, {nil, nil})

    fields = %{
      "assign_to" => attrs["assign_to"] || "",
      "node" => attrs["node"] || shared_node || "",
      "node_secret" => attrs["node_secret"] || shared_node_secret || "",
      "cookie" => attrs["cookie"] || shared_cookie || "",
      "cookie_secret" => attrs["cookie_secret"] || shared_cookie_secret || "",
      "use_node_secret" =>
        if(shared_node_secret, do: true, else: Map.get(attrs, "use_node_secret", false)),
      "use_cookie_secret" =>
        if(shared_cookie, do: false, else: Map.get(attrs, "use_cookie_secret", true))
    }

    intellisense_node = intellisense_node(fields)

    code = attrs["code"] || @default_code

    ctx = assign(ctx, fields: fields, code: code)

    {:ok, ctx,
     editor: [
       source: code,
       language: "elixir",
       intellisense_node: intellisense_node
     ]}
  end

  defp intellisense_node(fields) do
    node =
      if fields["use_node_secret"] do
        System.get_env("LB_#{fields["node_secret"]}")
      else
        fields["node"]
      end

    cookie =
      if fields["use_cookie_secret"] do
        System.get_env("LB_#{fields["cookie_secret"]}")
      else
        fields["cookie"]
      end

    if is_binary(node) and node =~ "@" and is_binary(cookie) and cookie != "" do
      {String.to_atom(node), String.to_atom(cookie)}
    end
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{fields: ctx.assigns.fields}
    {:ok, payload, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    ctx = update(ctx, :fields, &Map.put(&1, field, value))
    if field in @global_attrs, do: put_shared_attr(field, value)

    ctx =
      if field in @distribution_attrs do
        reconfigure_smart_cell(ctx,
          editor: [intellisense_node: intellisense_node(ctx.assigns.fields)]
        )
      else
        ctx
      end

    broadcast_event(ctx, "update_field", %{"fields" => update_fields(field, value)})

    {:noreply, ctx}
  end

  @impl true
  def handle_editor_change(source, ctx) do
    {:ok, assign(ctx, code: source)}
  end

  @impl true
  def to_attrs(ctx) do
    Map.put(ctx.assigns.fields, "code", ctx.assigns.code)
  end

  @impl true
  def to_source(%{"code" => ""}), do: ""
  def to_source(%{"use_node_secret" => false, "node" => ""}), do: ""
  def to_source(%{"use_node_secret" => true, "node_secret" => ""}), do: ""
  def to_source(%{"use_cookie_secret" => false, "cookie" => ""}), do: ""
  def to_source(%{"use_cookie_secret" => true, "cookie_secret" => ""}), do: ""

  def to_source(%{"code" => code, "assign_to" => var} = attrs) do
    var = if Kino.SmartCell.valid_variable_name?(var), do: var
    call = build_call(code) |> build_var(var)
    cookie = build_set_cookie(attrs)
    node = build_node(attrs)

    quote do
      require Kino.RPC

      node = unquote(node)
      Node.set_cookie(node, unquote(cookie))
      unquote(call)
    end
    |> Kino.SmartCell.quoted_to_string()
  end

  defp build_call(code) do
    quote do
      Kino.RPC.eval_string(node, unquote(quoted_code(code)), file: __ENV__.file)
    end
  end

  defp quoted_code(code) do
    {delimiter, code} =
      if String.contains?(code, ["\n", ~s/"/]) do
        {~s["""], code <> "\n"}
      else
        {~s["], code}
      end

    {:sigil_S, [delimiter: delimiter], [{:<<>>, [], [code]}, []]}
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

  defp build_node(%{"use_node_secret" => true, "node_secret" => secret}) do
    quote do
      String.to_atom(System.fetch_env!(unquote("LB_#{secret}")))
    end
  end

  defp build_node(%{"node" => node}), do: String.to_atom(node)

  defp put_shared_attr("cookie", value) do
    AttributeStore.put_attribute({@global_key, :cookie}, {value, nil})
  end

  defp put_shared_attr("cookie_secret", value) do
    AttributeStore.put_attribute({@global_key, :cookie}, {nil, value})
  end

  defp put_shared_attr("node", value) do
    AttributeStore.put_attribute({@global_key, :node}, {value, nil})
  end

  defp put_shared_attr("node_secret", value) do
    AttributeStore.put_attribute({@global_key, :node}, {nil, value})
  end

  defp update_fields(field, value), do: %{field => value}
end
