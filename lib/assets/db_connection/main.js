export function init(ctx, info) {
  ctx.importCSS("main.css");
  ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap");

  ctx.root.innerHTML = `
    <div class="app">
      <div id="info-box" class="info-box"></div>
      <div class="container">
        <div class="row header">
          <div class="inline-field">
            <label class="inline-input-label"> Connect to </label>
            <select class="input input--xs" name="type">
              <option value="postgres">PostgreSQL</option>
              <option value="mysql">MySQL</option>
            </select>
          </div>
          <div class="inline-field">
            <label class="inline-input-label"> Assign to </label>
            <input class="input input--xs input--text" name="variable" type="text" />
          </div>
        </div>
        <div class="row mixed-row">
          <div class="field grow">
            <label class="input-label">Hostname</label>
            <input class="input" name="hostname" type="text" />
          </div>
          <div class="field">
            <label class="input-label">Port</label>
            <input class="input input--xs input--number" name="port" type="number" />
          </div>
          <div class="field grow">
            <label class="input-label">Database</label>
            <input class="input" name="database" type="text" />
          </div>
        </div>
        <div class="row">
          <div class="field grow">
            <label class="input-label">User</label>
            <input class="input" name="username" type="text" />
          </div>
          <div class="field grow">
            <label class="input-label">Password</label>
            <input class="input" name="password" type="password" />
          </div>
        </div>
      </div>
    </div>
  `;

  updateInfoBox(info.missing_dep);
  setValues(info.fields);

  ctx.root.addEventListener("blur", handleFieldChange, true);
  ctx.root.addEventListener("change", handleFieldChange);

  function handleFieldChange(event) {
    const { name, value } = event.target;
    ctx.pushEvent("update_field", { field: name, value });
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
      infoBox.innerHTML = `<p>To successfully connect, you need to add the following dependency:</p><span>${dep}</span>`;
    } else {
      infoBox.classList.add("hidden");
    }
  }
}
