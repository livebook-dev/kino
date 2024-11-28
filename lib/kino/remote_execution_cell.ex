defmodule Kino.RemoteExecutionCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/remote_execution_cell/build"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Remote execution"

  alias Kino.AttributeStore

  @default_code ":ok"
  @global_key __MODULE__

  @impl true
  def init(attrs, ctx) do
    attrs = convert_legacy_attrs(attrs)

    shared_attrs = AttributeStore.get_attribute(@global_key, %{})
    attrs = Map.merge(shared_attrs, attrs)

    fields = %{
      "assign_to" => attrs["assign_to"] || "",
      "node_source" => attrs["node_source"] || "text",
      "node_text" => attrs["node_text"] || "",
      "node_secret" => attrs["node_secret"] || "",
      "node_variable" => attrs["node_variable"] || "",
      "cookie_source" => attrs["cookie_source"] || "text",
      "cookie_text" => attrs["cookie_text"] || "",
      "cookie_secret" => attrs["cookie_secret"] || "",
      "cookie_variable" => attrs["cookie_variable"] || ""
    }

    code = attrs["code"] || @default_code

    intellisense_node = intellisense_node(fields, [], [])

    ctx =
      assign(ctx,
        fields: fields,
        code: code,
        node_options: [],
        cookie_options: [],
        intellisense_node: intellisense_node
      )

    {:ok, ctx, editor: [source: code, language: "elixir", intellisense_node: intellisense_node]}
  end

  defp intellisense_node(fields, node_options, cookie_options) do
    node =
      case fields["node_source"] do
        "text" ->
          fields["node_text"]

        "secret" ->
          System.get_env("LB_#{fields["node_secret"]}")

        "variable" ->
          Enum.find_value(
            node_options,
            &(&1.variable == fields["node_variable"] && Atom.to_string(&1.value))
          )
      end

    cookie =
      case fields["cookie_source"] do
        "text" ->
          fields["cookie_text"]

        "secret" ->
          System.get_env("LB_#{fields["cookie_secret"]}")

        "variable" ->
          Enum.find_value(
            cookie_options,
            &(&1.variable == fields["cookie_variable"] && Atom.to_string(&1.value))
          )
      end

    if is_binary(node) and node =~ "@" and is_binary(cookie) and cookie != "" do
      {String.to_atom(node), String.to_atom(cookie)}
    end
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields,
      node_variables: Enum.map(ctx.assigns.node_options, & &1.variable),
      cookie_variables: Enum.map(ctx.assigns.cookie_options, & &1.variable)
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    updated_fields = to_updates(field, value)
    ctx = put_updated_fields(ctx, updated_fields)
    {:noreply, maybe_reconfigure_intellisese_node(ctx)}
  end

  defp put_updated_fields(ctx, updated_fields) do
    ctx = update(ctx, :fields, &Map.merge(&1, updated_fields))
    put_shared_attrs(ctx.assigns.fields)
    broadcast_event(ctx, "update_field", %{"fields" => updated_fields})
    ctx
  end

  defp maybe_reconfigure_intellisese_node(%{assigns: assigns} = ctx) do
    intellisense_node =
      intellisense_node(assigns.fields, assigns.node_options, assigns.cookie_options)

    if intellisense_node == assigns.intellisense_node do
      ctx
    else
      ctx
      |> assign(intellisense_node: intellisense_node)
      |> reconfigure_smart_cell(editor: [intellisense_node: intellisense_node])
    end
  end

  @impl true
  def handle_editor_change(source, ctx) do
    {:ok, assign(ctx, code: source)}
  end

  @impl true
  def scan_binding(pid, binding, _env) do
    node_options =
      for {key, value} <- binding,
          is_atom(key),
          is_atom(value) and Atom.to_string(value) =~ "@",
          do: %{variable: Atom.to_string(key), value: value}

    cookie_options =
      for {key, value} <- binding,
          is_atom(key),
          is_atom(value),
          do: %{variable: Atom.to_string(key), value: value}

    send(pid, {:scan_binding_result, node_options, cookie_options})
  end

  @impl true
  def handle_info({:scan_binding_result, node_options, cookie_options}, ctx) do
    ctx = assign(ctx, node_options: node_options, cookie_options: cookie_options)

    broadcast_event(ctx, "variables", %{
      node_variables: Enum.map(node_options, & &1.variable),
      cookie_variables: Enum.map(cookie_options, & &1.variable)
    })

    ctx = maybe_update_variable_fields(ctx)

    {:noreply, maybe_reconfigure_intellisese_node(ctx)}
  end

  defp maybe_update_variable_fields(%{assigns: assigns} = ctx) do
    updated_fields = %{}

    updated_fields =
      case {assigns.fields["node_variable"], assigns.node_options} do
        {"", [%{variable: variable} | _]} -> Map.put(updated_fields, "node_variable", variable)
        _ -> %{}
      end

    updated_fields =
      case {assigns.fields["cookie_variable"], assigns.cookie_options} do
        {"", [%{variable: variable} | _]} -> Map.put(updated_fields, "cookie_variable", variable)
        _ -> %{}
      end

    if updated_fields == %{} do
      ctx
    else
      put_updated_fields(ctx, updated_fields)
    end
  end

  @impl true
  def to_attrs(ctx) do
    fields = ctx.assigns.fields

    fields
    |> Map.take([
      "assign_to",
      "node_source",
      "node_#{fields["node_source"]}",
      "cookie_source",
      "cookie_#{fields["cookie_source"]}"
    ])
    |> Map.put("code", ctx.assigns.code)
  end

  @impl true
  def to_source(%{"code" => ""}), do: ""
  def to_source(%{"node_text" => ""}), do: ""
  def to_source(%{"node_secret" => ""}), do: ""
  def to_source(%{"node_variable" => ""}), do: ""
  def to_source(%{"cookie_text" => ""}), do: ""
  def to_source(%{"cookie_secret" => ""}), do: ""
  def to_source(%{"cookie_variable" => ""}), do: ""

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

  defp build_set_cookie(%{"cookie_secret" => secret}) do
    quote do
      String.to_atom(System.fetch_env!(unquote("LB_#{secret}")))
    end
  end

  defp build_set_cookie(%{"cookie_text" => cookie}) do
    String.to_atom(cookie)
  end

  defp build_set_cookie(%{"cookie_variable" => variable}) do
    {String.to_atom(variable), [], nil}
  end

  defp build_node(%{"node_secret" => secret}) do
    quote do
      String.to_atom(System.fetch_env!(unquote("LB_#{secret}")))
    end
  end

  defp build_node(%{"node_text" => node}) do
    String.to_atom(node)
  end

  defp build_node(%{"node_variable" => variable}) do
    {String.to_atom(variable), [], nil}
  end

  defp put_shared_attrs(fields) do
    shared_attrs =
      Map.take(fields, [
        "node_source",
        "node_#{fields["node_source"]}",
        "cookie_source",
        "cookie_#{fields["cookie_source"]}"
      ])

    AttributeStore.put_attribute(@global_key, shared_attrs)
  end

  defp to_updates(field, value), do: %{field => value}

  defp convert_legacy_attrs(attrs) do
    attrs =
      case attrs do
        %{"use_node_secret" => false, "node" => node} ->
          Map.merge(attrs, %{"node_source" => "text", "node_text" => node})

        %{"use_node_secret" => true, "node_secret" => secret} ->
          Map.merge(attrs, %{"node_source" => "secret", "node_secret" => secret})

        attrs ->
          attrs
      end

    case attrs do
      %{"use_cookie_secret" => false, "cookie" => cookie} ->
        Map.merge(attrs, %{"cookie_source" => "text", "cookie_text" => cookie})

      %{"use_cookie_secret" => true, "cookie_secret" => secret} ->
        Map.merge(attrs, %{"cookie_source" => "secret", "cookie_secret" => secret})

      attrs ->
        attrs
    end
  end
end
