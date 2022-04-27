export function init(ctx, payload) {
  ctx.importCSS("main.css");
  ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap");
  ctx.importCSS("https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.min.css");

  ctx.root.innerHTML = `
    <div class="app">
      <div>
        <div class="header">
          <div class="inline-field">
            <label class="inline-input-label">Query</label>
            <select class="input input--xs" name="connection_variable"></select>
          </div>
          <div class="inline-field">
            <label class="inline-input-label">Assign to</label>
            <input class="input input--xs input--text" type="text" name="result_variable" />
          </div>
          <div class="grow"></div>
          <button id="help-toggle" class="icon-button">
            <i class="ri ri-questionnaire-line" aria-hidden="true"></i>
          </button>
          <button id="settings-toggle" class="icon-button">
            <i class="ri ri-settings-3-line" aria-hidden="true"></i>
          </button>
        </div>
      </div>
      <div id="help-box" class="section info-box hidden">To dynamically inject values into the query use double curly braces, like {{name}}.</div>
      <div id="settings-box" class="section settings-box hidden">
        <div class="field">
          <label class="input-label">Timeout (s)</label>
          <input class="input input--xs" type="number" name="timeout" />
        </div>
      </div>
    </div>
  `;

  const state = {
    connections: payload.connections,
  };

  const connectionEl = ctx.root.querySelector(`[name="connection_variable"]`);
  renderConnectionSelect(payload.connections, payload.connection);

  const resultVariableEl = ctx.root.querySelector(`[name="result_variable"]`);
  resultVariableEl.value = payload.result_variable;

  const timeoutEl = ctx.root.querySelector(`[name="timeout"]`);
  timeoutEl.value = payload.timeout;

  const helpBoxEl = ctx.root.querySelector("#help-box");
  const helpToggleButton = ctx.root.querySelector("#help-toggle");
  const settingsBoxEl = ctx.root.querySelector("#settings-box");
  const settingsToggleButton = ctx.root.querySelector("#settings-toggle");

  resultVariableEl.addEventListener("blur", (event) => {
    ctx.pushEvent("update_result_variable", event.target.value);
  });

  connectionEl.addEventListener("change", (event) => {
    ctx.pushEvent("update_connection", event.target.value);
  });

  timeoutEl.addEventListener("change", (event) => {
    ctx.pushEvent("update_timeout", event.target.value);
  });

  helpToggleButton.addEventListener("click", (event) => {
    helpBoxEl.classList.toggle("hidden");
  });

  settingsToggleButton.addEventListener("click", (event) => {
    settingsBoxEl.classList.toggle("hidden");
  });

  ctx.handleEvent("update_result_variable", (variable) => {
    resultVariableEl.value = variable;
  });

  ctx.handleEvent("update_connection", (variable) => {
    const connection = state.connections.find(c => c.variable === variable)
    renderConnectionSelect(state.connections, connection);
  });

  ctx.handleEvent("update_timeout", (timeout) => {
    timeoutEl.value = timeout;
  });

  ctx.handleEvent("connections", ({ connections, connection }) => {
    state.connections = connections;
    renderConnectionSelect(connections, connection);
  });

  function renderConnectionSelect(connections, connection) {
    if (connection === null) {
      renderConnectionOptions([]);
      connectionEl.classList.add("nonexistent");
      connectionEl.disabled = true;
    } else if (connections.some((c) => c.variable === connection.variable)) {
      renderConnectionOptions(connections);
      connectionEl.value = connection.variable;
      connectionEl.classList.remove("nonexistent");
      connectionEl.disabled = false;
    } else {
      renderConnectionOptions([connection, ...connections]);
      connectionEl.value = connection.variable;
      connectionEl.classList.add("nonexistent");
      connectionEl.disabled = false;
    }
  }

  function renderConnectionOptions(connections) {
    const nameByType = { postgres: "PostgreSQL", mysql: "MySQL" };

    connectionEl.innerHTML = connections.map((connection) => `
      <option value="${connection.variable}">
        ${connection.variable} (${nameByType[connection.type]})
      </option>
    `).join("");
  }
}
