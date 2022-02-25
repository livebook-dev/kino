defmodule Kino.SmartCell.DBConnection do
  @moduledoc false

  # A smart cell used to establish connection to a database.

  use Kino.JS
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

  asset "main.js" do
    """
    export function init(ctx, info) {
      ctx.importCSS("main.css");
      ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap");

      ctx.root.innerHTML = `
        <div class="app">
          <div id="info-box" class="info-box"></div>
          <div>
            <div class="row">
              <input class="input input--xs" name="variable" type="text" />
              <div>=</div>
              <select class="input input--sm" name="type">
                <option value="postgres">PostgreSQL</option>
                <option value="mysql">MySQL</option>
              </select>
            </div>
            <div class="row">
              <div class="field grow">
                <label class="input-label">Hostname</label>
                <input class="input" name="hostname" type="text" />
              </div>
              <div class="field">
                <label class="input-label">Port</label>
                <input class="input input--xs" name="port" type="number" />
              </div>
            </div>
            <div class="row">
              <div class="field grow">
                <label class="input-label">User</label>
                <input class="input" name="username" type="text" />
              </div>
            </div>
            <div class="row">
              <div class="field grow">
                <label class="input-label">Password</label>
                <input class="input" name="password" type="password" />
              </div>
            </div>
            <div class="row">
              <div class="field grow">
                <label class="input-label">Database</label>
                <input class="input" name="database" type="text" />
              </div>
            </div>
          </div>
        </div>
      `;

      setValues(info.fields);

      updateInfoBox(info.missing_dep);

      ctx.root.addEventListener("blur", handleChange, true);
      ctx.root.addEventListener("change", handleChange);

      function handleChange(event) {
        const { value, name } = event.target;
        ctx.pushEvent("update", { field: name, value });
      }

      ctx.handleEvent("update", ({ fields }) => {
        setValues(fields);
      });

      ctx.handleEvent("missing_dep", ({ dep }) => {
        updateInfoBox(dep);
      });

      function setValues(fields) {
        for (const field in fields) {
          ctx.root.querySelector(`[name="${field}"]`).value = fields[field];
        }
      }

      function updateInfoBox(dep) {
        const infoBox = ctx.root.querySelector("#info-box");

        if (dep) {
          infoBox.classList.remove("hidden");
          infoBox.textContent = `To successfully connect, you need to add the following dependency:\n\n    ${dep}`;
        } else {
          infoBox.classList.add("hidden");
        }
      }
    }
    """
  end

  asset "main.css" do
    """
    .app {
      font-family: "Inter";

      box-sizing: border-box;

      --gray-50: #f8fafc;
      --gray-100: #f0f5f9;
      --gray-200: #e1e8f0;
      --gray-400: #91a4b7;
      --gray-500: #61758a;
      --gray-600: #445668;
      --gray-800: #1c2a3a;
    }

    .row {
      display: flex;
      align-items: center;
    }

    .row > *:not(:first-child) {
      margin-left: 8px;
    }

    .row:not(:first-child) {
      margin-top: 12px;
    }

    .input {
      padding: 8px 12px;
      background-color: var(--gray-50);
      font-size: 0.875rem;
      border: 1px solid var(--gray-200);
      border-radius: 0.5rem;
      color: var(--gray-600);
    }

    .input::placeholder {
      color: var(--gray-400);
    }

    .input:focus {
      outline: none;
    }

    .input--sm {
      width: auto;
      min-width: 300px;
    }

    .input--xs {
      width: auto;
      min-width: 150px;
    }

    .input-label {
      display: block;
      margin-bottom: 2px;
      font-size: 0.875rem;
      color: var(--gray-800);
      font-weight: 500;
    }

    .field {
      display: flex;
      flex-direction: column;
    }

    .grow {
      flex-grow: 1;
    }

    .info-box {
      margin-bottom: 24px;
      padding: 16px;
      border-radius: 0.5rem;
      white-space: pre-wrap;
      font-weight: 500;
      font-size: 0.875rem;
      background-color: var(--gray-100);
      color: var(--gray-500);
    }

    .hidden {
      display: none;
    }
    """
  end
end
